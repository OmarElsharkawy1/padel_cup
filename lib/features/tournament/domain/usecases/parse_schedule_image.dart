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

    // ── Find VS markers ──
    final vsBlocks = <_VsMarker>[];
    for (final block in blocks) {
      for (final line in block.lines) {
        final text = line.text.trim().toUpperCase();
        if (text == 'VS' || text == 'ضد') {
          final rect = line.boundingBox;
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
    // Sort VS markers by X to identify 4 columns (courts)
    final sortedByX = List.of(vsBlocks)..sort((a, b) => a.centerX.compareTo(b.centerX));

    // Cluster into 4 columns using gaps
    final columns = _clusterByX(sortedByX);

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
    final matches = <ParsedMatch>[];
    final groupATeams = <String>{};
    final groupBTeams = <String>{};

    for (final entry in courtAssignments.entries) {
      final court = entry.value;

      // Sort VS markers in this column by Y (top to bottom = round order)
      final sortedVs = List.of(court.vsMarkers)
        ..sort((a, b) => a.centerY.compareTo(b.centerY));

      for (var roundIdx = 0; roundIdx < sortedVs.length; roundIdx++) {
        final vs = sortedVs[roundIdx];

        final above = _findClosest(allElements, vs.centerX, vs.top, above: true);
        final below = _findClosest(allElements, vs.centerX, vs.bottom, above: false);

        if (above == null || below == null) continue;

        final team1 = _normalizeTeamName(above.text);
        final team2 = _normalizeTeamName(below.text);
        final roundNumber = roundIdx + 1;

        matches.add(ParsedMatch(
          roundNumber: roundNumber,
          courtNumber: court.courtNumber,
          team1Name: team1,
          team2Name: team2,
          groupId: court.groupId,
        ));

        if (court.groupId == 'A') {
          groupATeams.add(team1);
          groupATeams.add(team2);
        } else {
          groupBTeams.add(team1);
          groupBTeams.add(team2);
        }
      }
    }

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
    return text
        .trim()
        .replaceAll(RegExp(r'\s*\+\s*'), ' + ')
        .replaceAll(RegExp(r'\s{2,}'), ' ');
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
