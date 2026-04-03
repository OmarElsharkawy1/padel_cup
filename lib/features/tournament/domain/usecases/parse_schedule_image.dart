import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// A single parsed match from the image.
class ParsedMatch {
  final int roundNumber;
  final int courtNumber;
  final String team1Name;
  final String team2Name;
  final String groupId; // 'A' or 'B'

  const ParsedMatch({
    required this.roundNumber,
    required this.courtNumber,
    required this.team1Name,
    required this.team2Name,
    required this.groupId,
  });
}

/// Full result of parsing a schedule image.
class ParsedSchedule {
  final List<String> groupATeams;
  final List<String> groupBTeams;
  final List<ParsedMatch> matches;

  const ParsedSchedule({
    required this.groupATeams,
    required this.groupBTeams,
    required this.matches,
  });

  bool get hasMatches => matches.isNotEmpty;
  bool get hasTeams => groupATeams.isNotEmpty || groupBTeams.isNotEmpty;
}

class ParseScheduleImage {
  const ParseScheduleImage();

  Future<ParsedSchedule> call(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer();

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      return _parseBlocks(recognizedText);
    } finally {
      textRecognizer.close();
    }
  }

  ParsedSchedule _parseBlocks(RecognizedText recognizedText) {
    final blocks = recognizedText.blocks;
    if (blocks.isEmpty) {
      return const ParsedSchedule(
        groupATeams: [],
        groupBTeams: [],
        matches: [],
      );
    }

    // ── Build text elements (skip headers/markers) ──
    final allElements = <_TextElement>[];
    for (final block in blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isEmpty) continue;
        final upper = text.toUpperCase();
        if (upper == 'VS' ||
            upper == 'ضد' ||
            upper.contains('GROUP') ||
            upper.contains('COURT') ||
            upper.contains('TIME') ||
            upper.contains('FINAL') ||
            upper.contains('مجموعة') ||
            upper.contains('ملعب') ||
            _isTimeString(upper) ||
            _isHeaderRow(upper)) {
          continue;
        }
        final rect = line.boundingBox;
        allElements.add(_TextElement(
          text: text,
          centerX: rect.center.dx,
          centerY: rect.center.dy,
          top: rect.top,
          bottom: rect.bottom,
          left: rect.left,
          right: rect.right,
        ));
      }
    }

    // ── Find VS markers (broad matching for OCR errors) ──
    final vsBlocks = <_VsMarker>[];
    for (final block in blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        final upper = text.toUpperCase();
        // Match: "VS", "Vs", "vs", "V5", "V$", "ضد", or any 2-char
        // string that looks like VS
        if (upper == 'VS' ||
            upper == 'ضد' ||
            upper == 'V5' ||
            upper == 'V\$' ||
            upper == 'VŠ' ||
            (text.length <= 3 && RegExp(r'^[Vv][Ss5\$]$').hasMatch(text))) {
          final rect = line.boundingBox;
          vsBlocks.add(_VsMarker(
            centerX: rect.center.dx,
            centerY: rect.center.dy,
            top: rect.top,
            bottom: rect.bottom,
          ));
        }
      }
      // Also check at block level (sometimes VS is a standalone block)
      final blockText = block.text.trim().toUpperCase();
      if (blockText == 'VS' || blockText == 'ضد') {
        // Check we didn't already add it from the line scan
        final rect = block.boundingBox;
        final alreadyAdded = vsBlocks.any((v) =>
            (v.centerX - rect.center.dx).abs() < 10 &&
            (v.centerY - rect.center.dy).abs() < 10);
        if (!alreadyAdded) {
          vsBlocks.add(_VsMarker(
            centerX: rect.center.dx,
            centerY: rect.center.dy,
            top: rect.top,
            bottom: rect.bottom,
          ));
        }
      }
    }

    // ── Determine court columns by clustering VS X positions ──
    final sortedByX = List.of(vsBlocks)
      ..sort((a, b) => a.centerX.compareTo(b.centerX));

    // Cluster into 4 columns using gaps
    var columns = _clusterByX(sortedByX);

    // ── Validate: each column should have 5 VS markers (5 rounds) ──
    // If a column is short, try to infer the missing VS position
    // from the Y positions of the other columns' VS markers in the same row
    if (columns.length == 4) {
      final expectedPerColumn =
          columns.map((c) => c.length).reduce((a, b) => a > b ? a : b);

      for (var colIdx = 0; colIdx < columns.length; colIdx++) {
        if (columns[colIdx].length < expectedPerColumn) {
          // Find Y positions that exist in other columns but not this one
          final thisYs =
              columns[colIdx].map((v) => v.centerY).toList()..sort();
          final avgX = columns[colIdx]
                  .map((v) => v.centerX)
                  .reduce((a, b) => a + b) /
              columns[colIdx].length;

          // Collect all Y positions from all columns
          final allYRows = <double>[];
          for (final col in columns) {
            for (final v in col) {
              allYRows.add(v.centerY);
            }
          }
          // Cluster Y positions into rows
          allYRows.sort();
          final yRows = _clusterYPositions(allYRows, expectedPerColumn);

          for (final rowY in yRows) {
            // Check if this column has a VS near this Y
            final hasIt = thisYs.any((y) => (y - rowY).abs() < 40);
            if (!hasIt) {
              // Infer a missing VS marker
              columns[colIdx].add(_VsMarker(
                centerX: avgX,
                centerY: rowY,
                top: rowY - 10,
                bottom: rowY + 10,
              ));
            }
          }
        }
      }
    }

    // Assign court numbers (1-4) and group IDs based on position
    // Courts 1,2 = Group A (left half), Courts 3,4 = Group B (right half)
    final courtAssignments = <int, _CourtInfo>{};
    for (var i = 0; i < columns.length && i < 4; i++) {
      final courtNum = i + 1;
      final groupId = courtNum <= 2 ? 'A' : 'B';
      courtAssignments[i] = _CourtInfo(
        courtNumber: courtNum,
        groupId: groupId,
        vsMarkers: columns[i],
      );
    }

    // ── For each VS marker, find team above and below → build matches ──
    // First pass: collect all raw team names per group
    final rawMatches = <({String team1, String team2, int round, int court, String group})>[];
    final groupATeams = <String>{};
    final groupBTeams = <String>{};

    for (final entry in courtAssignments.entries) {
      final court = entry.value;
      final sortedVs = List.of(court.vsMarkers)
        ..sort((a, b) => a.centerY.compareTo(b.centerY));

      for (var roundIdx = 0; roundIdx < sortedVs.length; roundIdx++) {
        final vs = sortedVs[roundIdx];
        final above = _findClosest(allElements, vs.centerX, vs.top, above: true);
        final below = _findClosest(allElements, vs.centerX, vs.bottom, above: false);
        if (above == null || below == null) continue;

        final team1Raw = _normalizeTeamName(above.text);
        final team2Raw = _normalizeTeamName(below.text);

        // Fuzzy-deduplicate against already-seen names in this group
        final targetSet = court.groupId == 'A' ? groupATeams : groupBTeams;
        final team1 = _findCanonicalName(team1Raw, targetSet);
        final team2 = _findCanonicalName(team2Raw, targetSet);

        targetSet.add(team1);
        targetSet.add(team2);

        rawMatches.add((
          team1: team1,
          team2: team2,
          round: roundIdx + 1,
          court: court.courtNumber,
          group: court.groupId,
        ));
      }
    }

    // Build final match list with canonical names
    final matches = rawMatches
        .map((m) => ParsedMatch(
              roundNumber: m.round,
              courtNumber: m.court,
              team1Name: m.team1,
              team2Name: m.team2,
              groupId: m.group,
            ))
        .toList();

    return ParsedSchedule(
      groupATeams: groupATeams.toList(),
      groupBTeams: groupBTeams.toList(),
      matches: matches,
    );
  }

  /// Clusters VS markers into columns by X position.
  List<List<_VsMarker>> _clusterByX(List<_VsMarker> sorted) {
    if (sorted.isEmpty) return [];

    final columns = <List<_VsMarker>>[
      [sorted.first]
    ];

    for (var i = 1; i < sorted.length; i++) {
      final current = sorted[i];
      final lastColumnAvgX = columns.last
              .map((v) => v.centerX)
              .reduce((a, b) => a + b) /
          columns.last.length;

      // If this marker is close to the last column's average X, add to same column
      if ((current.centerX - lastColumnAvgX).abs() < 100) {
        columns.last.add(current);
      } else {
        columns.add([current]);
      }
    }

    return columns;
  }

  /// Clusters Y positions into [expectedCount] rows by averaging nearby values.
  List<double> _clusterYPositions(List<double> sortedYs, int expectedCount) {
    if (sortedYs.isEmpty) return [];

    final clusters = <List<double>>[
      [sortedYs.first]
    ];
    for (var i = 1; i < sortedYs.length; i++) {
      final current = sortedYs[i];
      final lastAvg =
          clusters.last.reduce((a, b) => a + b) / clusters.last.length;
      if ((current - lastAvg).abs() < 40) {
        clusters.last.add(current);
      } else {
        clusters.add([current]);
      }
    }

    return clusters
        .map((c) => c.reduce((a, b) => a + b) / c.length)
        .take(expectedCount)
        .toList();
  }

  _TextElement? _findClosest(
    List<_TextElement> elements,
    double targetX,
    double targetY, {
    required bool above,
  }) {
    _TextElement? best;
    double bestDist = double.infinity;

    for (final e in elements) {
      if (above && e.bottom > targetY) continue;
      if (!above && e.top < targetY) continue;

      final xDist = (e.centerX - targetX).abs();
      if (xDist > 200) continue;

      final yDist = above ? (targetY - e.bottom) : (e.top - targetY);
      final dist = yDist + xDist * 0.3;

      if (dist < bestDist) {
        bestDist = dist;
        best = e;
      }
    }
    return best;
  }

  bool _isTimeString(String text) {
    return RegExp(r'^\d{1,2}:\d{2}$').hasMatch(text);
  }

  bool _isHeaderRow(String text) {
    final lower = text.toLowerCase();
    return lower == '1st group a' ||
        lower == '1st group b' ||
        lower == '2nd group a' ||
        lower == '2nd group b' ||
        lower.contains('1st group') ||
        lower.contains('2nd group');
  }

  String _normalizeTeamName(String text) {
    var result = text.trim();

    // Fix common OCR character misreads
    result = result
        .replaceAll('|', 'I')   // pipe → I
        .replaceAll('l', 'I')   // lowercase L → I (only in uppercase context)
        .replaceAll(',', '.')   // comma → period (M, Elkomy → M. Elkomy)
        .replaceAll(';', '.')   // semicolon → period
        .replaceAll('0', 'O')  // zero → O (in name context)
        ;

    // But we need to be smarter — only replace in name parts, not everywhere.
    // Revert: let's do targeted fixes instead.
    result = text.trim();

    // Fix pipe/bar → I (very common OCR error)
    result = result.replaceAll('|', 'I');

    // Fix comma used as period in abbreviations like "M, ELKOMY" → "M. ELKOMY"
    result = result.replaceAllMapped(
      RegExp(r'(\b[A-Z]),(\s)'),
      (m) => '${m[1]}.${m[2]}',
    );

    // Normalize spacing around +
    result = result
        .replaceAll(RegExp(r'\s*\+\s*'), ' + ')
        .replaceAll(RegExp(r'\s{2,}'), ' ');

    return result;
  }

  /// Finds an existing team name that is a fuzzy match for [name],
  /// or returns [name] itself if no match found.
  String _findCanonicalName(String name, Set<String> existingNames) {
    // Exact match
    if (existingNames.contains(name)) return name;

    // Fuzzy match: compare with similarity threshold
    for (final existing in existingNames) {
      if (_isFuzzyMatch(name, existing)) return existing;
    }

    return name;
  }

  /// Returns true if two strings are very similar (likely OCR variants).
  /// Uses character-level comparison with a tolerance for 1-2 char differences.
  bool _isFuzzyMatch(String a, String b) {
    if (a == b) return true;

    // Length difference > 2 means they're probably different teams
    if ((a.length - b.length).abs() > 2) return false;

    // Compare normalized (case-insensitive, stripped of punctuation)
    final normA = a.toUpperCase().replaceAll(RegExp(r'[^A-Z\s+]'), '');
    final normB = b.toUpperCase().replaceAll(RegExp(r'[^A-Z\s+]'), '');

    if (normA == normB) return true;

    // Levenshtein distance: allow up to 2 edits for names > 5 chars
    final dist = _levenshtein(normA, normB);
    final threshold = normA.length > 10 ? 2 : 1;
    return dist <= threshold;
  }

  int _levenshtein(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final matrix = List.generate(
      a.length + 1,
      (i) => List.generate(b.length + 1, (j) => 0),
    );

    for (var i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[a.length][b.length];
  }
}

class _TextElement {
  final String text;
  final double centerX;
  final double centerY;
  final double top;
  final double bottom;
  final double left;
  final double right;

  const _TextElement({
    required this.text,
    required this.centerX,
    required this.centerY,
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
  });
}

class _VsMarker {
  final double centerX;
  final double centerY;
  final double top;
  final double bottom;

  const _VsMarker({
    required this.centerX,
    required this.centerY,
    required this.top,
    required this.bottom,
  });
}

class _CourtInfo {
  final int courtNumber;
  final String groupId;
  final List<_VsMarker> vsMarkers;

  const _CourtInfo({
    required this.courtNumber,
    required this.groupId,
    required this.vsMarkers,
  });
}
