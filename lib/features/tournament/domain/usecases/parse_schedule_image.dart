import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// A single parsed match from the image.
class ParsedMatch {
  final int roundNumber;
  final int courtNumber;
  final String team1Name;
  final String team2Name;
  final String groupId;

  const ParsedMatch({
    required this.roundNumber,
    required this.courtNumber,
    required this.team1Name,
    required this.team2Name,
    required this.groupId,
  });
}

/// Result of parsing a schedule image.
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
      return _parse(recognizedText);
    } finally {
      textRecognizer.close();
    }
  }

  ParsedSchedule _parse(RecognizedText recognizedText) {
    final blocks = recognizedText.blocks;
    if (blocks.isEmpty) {
      return const ParsedSchedule(
          groupATeams: [], groupBTeams: [], matches: []);
    }

    final midX = _findMidX(blocks);

    // ── Step 1: Collect text elements (lines containing "+") ──
    final allElements = <_TextElement>[];
    for (final block in blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (!text.contains('+')) continue;

        final upper = text.toUpperCase();
        if (upper.contains('GROUP') ||
            upper.contains('COURT') ||
            upper.contains('FINAL') ||
            upper.contains('مجموعة')) {
          continue;
        }

        final plusCount = '+'.allMatches(text).length;
        if (plusCount == 1) {
          final rect = line.boundingBox;
          allElements.add(_TextElement(
            text: text,
            centerX: rect.center.dx,
            centerY: rect.center.dy,
            top: rect.top,
            bottom: rect.bottom,
          ));
        } else {
          // Multiple teams in one line — split using word bounding boxes
          _splitMultiTeamLine(line, allElements);
        }
      }
    }

    // ── Step 2: Find VS markers ──
    final vsMarkers = <_VsMarker>[];
    for (final block in blocks) {
      for (final line in block.lines) {
        if (_isVs(line.text)) {
          final r = line.boundingBox;
          _addVsUnique(vsMarkers, r.center.dx, r.center.dy, r.top, r.bottom);
        }
      }
      if (_isVs(block.text)) {
        final r = block.boundingBox;
        _addVsUnique(vsMarkers, r.center.dx, r.center.dy, r.top, r.bottom);
      }
    }

    if (vsMarkers.length < 4) {
      return _namesOnly(allElements, midX);
    }

    // ── Step 3: Cluster VS into 4 columns ──
    final sortedByX = List.of(vsMarkers)
      ..sort((a, b) => a.centerX.compareTo(b.centerX));

    var columns = <List<_VsMarker>>[];
    for (final threshold in [150, 120, 100, 80, 60, 40]) {
      columns = _clusterByX(sortedByX, threshold.toDouble());
      if (columns.length == 4) break;
    }
    if (columns.length != 4) {
      columns = _forceNClusters(sortedByX, 4);
    }
    if (columns.length != 4) {
      return _namesOnly(allElements, midX);
    }

    // Fill missing VS markers (each column should have 5)
    _fillMissingVs(columns);

    // Sort each column by Y
    for (final col in columns) {
      col.sort((a, b) => a.centerY.compareTo(b.centerY));
    }

    // ── Step 4: Column X boundaries ──
    final colCenterXs = columns
        .map((col) =>
            col.map((v) => v.centerX).reduce((a, b) => a + b) / col.length)
        .toList();

    final colBounds = <({double minX, double maxX})>[];
    for (var i = 0; i < 4; i++) {
      final left =
          i == 0 ? 0.0 : (colCenterXs[i - 1] + colCenterXs[i]) / 2;
      final right = i == 3
          ? double.infinity
          : (colCenterXs[i] + colCenterXs[i + 1]) / 2;
      colBounds.add((minX: left, maxX: right));
    }

    // Partition text elements into columns
    final colElements = List.generate(4, (_) => <_TextElement>[]);
    for (final elem in allElements) {
      for (var i = 0; i < 4; i++) {
        if (elem.centerX >= colBounds[i].minX &&
            elem.centerX < colBounds[i].maxX) {
          colElements[i].add(elem);
          break;
        }
      }
    }

    // ── Step 5: Match text to VS markers (consumed) ──
    final rawMatches =
        <({String team1, String team2, int round, int court, String group})>[];
    final groupATeams = <String>{};
    final groupBTeams = <String>{};

    for (var ci = 0; ci < 4; ci++) {
      final courtNum = ci + 1;
      final groupId = courtNum <= 2 ? 'A' : 'B';
      final colTexts = colElements[ci]
        ..sort((a, b) => a.centerY.compareTo(b.centerY));
      final colVs = columns[ci];
      final usedTexts = <int>{};

      for (var ri = 0; ri < colVs.length; ri++) {
        final vs = colVs[ri];

        // Closest unused text above
        int? aboveIdx;
        double bestAbove = double.infinity;
        for (var ti = 0; ti < colTexts.length; ti++) {
          if (usedTexts.contains(ti)) continue;
          if (colTexts[ti].centerY >= vs.centerY) continue;
          final dist = vs.centerY - colTexts[ti].centerY;
          if (dist < bestAbove) {
            bestAbove = dist;
            aboveIdx = ti;
          }
        }

        // Closest unused text below
        int? belowIdx;
        double bestBelow = double.infinity;
        for (var ti = 0; ti < colTexts.length; ti++) {
          if (usedTexts.contains(ti)) continue;
          if (ti == aboveIdx) continue;
          if (colTexts[ti].centerY <= vs.centerY) continue;
          final dist = colTexts[ti].centerY - vs.centerY;
          if (dist < bestBelow) {
            bestBelow = dist;
            belowIdx = ti;
          }
        }

        if (aboveIdx == null || belowIdx == null) continue;
        usedTexts.add(aboveIdx);
        usedTexts.add(belowIdx);

        final team1Raw = _normalizeTeamName(colTexts[aboveIdx].text);
        final team2Raw = _normalizeTeamName(colTexts[belowIdx].text);

        final targetSet = groupId == 'A' ? groupATeams : groupBTeams;
        final team1 = _findCanonicalName(team1Raw, targetSet);
        final team2 = _findCanonicalName(team2Raw, targetSet);
        targetSet.add(team1);
        targetSet.add(team2);

        rawMatches.add((
          team1: team1,
          team2: team2,
          round: ri + 1,
          court: courtNum,
          group: groupId,
        ));
      }
    }

    // ── Step 6: Enforce 5 teams per group ──
    final canonicalA = _reduceToN(groupATeams, 5);
    final canonicalB = _reduceToN(groupBTeams, 5);

    final nameMap = <String, String>{};
    for (final n in groupATeams) {
      nameMap[n] = _findCanonicalName(n, canonicalA);
    }
    for (final n in groupBTeams) {
      nameMap[n] = _findCanonicalName(n, canonicalB);
    }

    final matches = rawMatches
        .map((m) => ParsedMatch(
              roundNumber: m.round,
              courtNumber: m.court,
              team1Name: nameMap[m.team1] ?? m.team1,
              team2Name: nameMap[m.team2] ?? m.team2,
              groupId: m.group,
            ))
        .toList();

    return ParsedSchedule(
      groupATeams: canonicalA.toList(),
      groupBTeams: canonicalB.toList(),
      matches: matches,
    );
  }

  // ── Fallback: names only ──

  ParsedSchedule _namesOnly(List<_TextElement> elements, double midX) {
    final groupA = <String>{};
    final groupB = <String>{};

    for (final elem in elements) {
      if (!elem.text.contains('+')) continue;
      final name = _normalizeTeamName(elem.text);
      final isA = elem.centerX < midX;
      final targetSet = isA ? groupA : groupB;
      final canonical = _findCanonicalName(name, targetSet);
      targetSet.add(canonical);
    }

    return ParsedSchedule(
      groupATeams: _reduceToN(groupA, 5).toList(),
      groupBTeams: _reduceToN(groupB, 5).toList(),
      matches: [],
    );
  }

  // ── Multi-team line split ──

  void _splitMultiTeamLine(TextLine line, List<_TextElement> output) {
    final words = line.elements.map((e) {
      final r = e.boundingBox;
      return (text: e.text.trim(), left: r.left, right: r.right,
              centerX: r.center.dx, centerY: r.center.dy,
              top: r.top, bottom: r.bottom);
    }).toList();

    final plusIndices = <int>[];
    for (var i = 0; i < words.length; i++) {
      if (words[i].text == '+') plusIndices.add(i);
    }

    if (plusIndices.length <= 1) {
      final r = line.boundingBox;
      output.add(_TextElement(
        text: line.text.trim(),
        centerX: r.center.dx, centerY: r.center.dy,
        top: r.top, bottom: r.bottom,
      ));
      return;
    }

    // Find split points between consecutive "+" groups (largest X gap)
    final splits = <int>[];
    for (var i = 0; i < plusIndices.length - 1; i++) {
      final from = plusIndices[i] + 1;
      final to = plusIndices[i + 1];
      double maxGap = 0;
      int bestSplit = to;
      for (var j = from + 1; j <= to && j < words.length; j++) {
        final gap = words[j].left - words[j - 1].right;
        if (gap > maxGap) {
          maxGap = gap;
          bestSplit = j;
        }
      }
      splits.add(bestSplit);
    }

    var start = 0;
    for (final split in splits) {
      _emitWords(words, start, split, output);
      start = split;
    }
    _emitWords(words, start, words.length, output);
  }

  void _emitWords(List<dynamic> words, int from, int to,
      List<_TextElement> output) {
    if (from >= to) return;
    final slice = words.sublist(from, to.clamp(0, words.length));
    final text = slice.map((w) => w.text as String).join(' ');
    if (!text.contains('+')) return;
    output.add(_TextElement(
      text: text,
      centerX: (slice.first.centerX + slice.last.centerX) / 2,
      centerY: slice.first.centerY as double,
      top: slice.first.top as double,
      bottom: slice.first.bottom as double,
    ));
  }

  // ── VS detection ──

  bool _isVs(String text) {
    final t = text.trim().toUpperCase();
    return t == 'VS' || t == 'ضد' || t == 'V5' ||
        (text.trim().length <= 3 &&
            RegExp(r'^[Vv][Ss5\$]$').hasMatch(text.trim()));
  }

  void _addVsUnique(List<_VsMarker> list, double cx, double cy,
      double t, double b) {
    final isDupe = list.any(
        (v) => (v.centerX - cx).abs() < 20 && (v.centerY - cy).abs() < 20);
    if (!isDupe) {
      list.add(_VsMarker(centerX: cx, centerY: cy, top: t, bottom: b));
    }
  }

  // ── Clustering ──

  List<List<_VsMarker>> _clusterByX(List<_VsMarker> sorted, double threshold) {
    if (sorted.isEmpty) return [];
    final cols = <List<_VsMarker>>[[sorted.first]];
    for (var i = 1; i < sorted.length; i++) {
      final avgX = cols.last.map((v) => v.centerX).reduce((a, b) => a + b) /
          cols.last.length;
      if ((sorted[i].centerX - avgX).abs() < threshold) {
        cols.last.add(sorted[i]);
      } else {
        cols.add([sorted[i]]);
      }
    }
    return cols;
  }

  List<List<_VsMarker>> _forceNClusters(List<_VsMarker> sorted, int n) {
    if (sorted.length < n) return [sorted];
    final gaps = <({int index, double gap})>[];
    for (var i = 1; i < sorted.length; i++) {
      gaps.add((index: i, gap: sorted[i].centerX - sorted[i - 1].centerX));
    }
    gaps.sort((a, b) => b.gap.compareTo(a.gap));
    final splitIndices = gaps.take(n - 1).map((g) => g.index).toList()..sort();
    final clusters = <List<_VsMarker>>[];
    var start = 0;
    for (final split in splitIndices) {
      clusters.add(sorted.sublist(start, split));
      start = split;
    }
    clusters.add(sorted.sublist(start));
    return clusters;
  }

  void _fillMissingVs(List<List<_VsMarker>> columns) {
    final maxLen = columns.map((c) => c.length).reduce((a, b) => a > b ? a : b);
    final allY = <double>[];
    for (final col in columns) {
      for (final v in col) {
        allY.add(v.centerY);
      }
    }
    allY.sort();

    // Cluster Y into rows
    final rows = <List<double>>[
      [allY.first]
    ];
    for (var i = 1; i < allY.length; i++) {
      if ((allY[i] - rows.last.first).abs() < 40) {
        rows.last.add(allY[i]);
      } else {
        rows.add([allY[i]]);
      }
    }
    final yRows =
        rows.take(maxLen).map((r) => r.reduce((a, b) => a + b) / r.length);

    for (var ci = 0; ci < columns.length; ci++) {
      if (columns[ci].length >= maxLen) continue;
      final avgX = columns[ci].map((v) => v.centerX).reduce((a, b) => a + b) /
          columns[ci].length;
      for (final rowY in yRows) {
        final hasIt = columns[ci].any((v) => (v.centerY - rowY).abs() < 40);
        if (!hasIt) {
          columns[ci].add(_VsMarker(
              centerX: avgX, centerY: rowY, top: rowY - 10, bottom: rowY + 10));
        }
      }
    }
  }

  // ── Helpers ──

  double _findMidX(List<TextBlock> blocks) {
    double? aX, bX;
    for (final block in blocks) {
      final t = block.text.trim().toUpperCase();
      if (t.contains('GROUP A') || t.contains('مجموعة أ')) {
        aX = block.boundingBox.center.dx;
      } else if (t.contains('GROUP B') || t.contains('مجموعة ب')) {
        bX = block.boundingBox.center.dx;
      }
    }
    if (aX != null && bX != null) return (aX + bX) / 2;
    double maxX = 0;
    for (final b in blocks) {
      if (b.boundingBox.right > maxX) maxX = b.boundingBox.right;
    }
    return maxX / 2;
  }

  String _normalizeTeamName(String text) {
    var r = text.trim();
    r = r.replaceAll('|', 'I');
    r = r.replaceAllMapped(
        RegExp(r'(\b[A-Z]),(\s)'), (m) => '${m[1]}.${m[2]}');
    r = r.replaceAll(RegExp(r'\s*\+\s*'), ' + ')
        .replaceAll(RegExp(r'\s{2,}'), ' ');
    return r;
  }

  String _findCanonicalName(String name, Set<String> existing) {
    if (existing.contains(name)) return name;
    for (final e in existing) {
      if (_isFuzzyMatch(name, e)) return e;
    }
    return name;
  }

  bool _isFuzzyMatch(String a, String b) {
    if (a == b) return true;
    final nA = a.toUpperCase().replaceAll(RegExp(r'[^A-Z\s+]'), '');
    final nB = b.toUpperCase().replaceAll(RegExp(r'[^A-Z\s+]'), '');
    if (nA == nB) return true;

    // Suffix/prefix match around "+"
    if (nA.contains('+') && nB.contains('+')) {
      final pA = nA.split('+').map((s) => s.trim()).toList();
      final pB = nB.split('+').map((s) => s.trim()).toList();
      if (pA.length == 2 && pB.length == 2) {
        if (pA[1] == pB[1] &&
            (pA[0].endsWith(pB[0]) || pB[0].endsWith(pA[0]))) {
          return true;
        }
        if (pA[0] == pB[0] &&
            (pA[1].endsWith(pB[1]) || pB[1].endsWith(pA[1]))) {
          return true;
        }
      }
    }

    if ((nA.length - nB.length).abs() > 2) return false;
    return _levenshtein(nA, nB) <= (nA.length > 10 ? 2 : 1);
  }

  Set<String> _reduceToN(Set<String> teams, int n) {
    if (teams.length <= n) return teams;
    final list = teams.toList();
    while (list.length > n) {
      int bestI = 0, bestJ = 1, bestScore = -1;
      for (var i = 0; i < list.length; i++) {
        for (var j = i + 1; j < list.length; j++) {
          final s = _similarityScore(list[i], list[j]);
          if (s > bestScore) {
            bestScore = s;
            bestI = i;
            bestJ = j;
          }
        }
      }
      list.removeAt(list[bestI].length >= list[bestJ].length ? bestJ : bestI);
    }
    return list.toSet();
  }

  int _similarityScore(String a, String b) {
    if (a == b) return 1000;
    final nA = a.toUpperCase().replaceAll(RegExp(r'[^A-Z\s+]'), '');
    final nB = b.toUpperCase().replaceAll(RegExp(r'[^A-Z\s+]'), '');
    if (nA == nB) return 999;
    if (nA.contains(nB) || nB.contains(nA)) return 850;
    final d = _levenshtein(nA, nB);
    return d <= 3 ? 700 - d * 10 : 0;
  }

  int _levenshtein(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final m = List.generate(
        a.length + 1, (i) => List.generate(b.length + 1, (j) => 0));
    for (var i = 0; i <= a.length; i++) {
      m[i][0] = i;
    }
    for (var j = 0; j <= b.length; j++) {
      m[0][j] = j;
    }
    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final c = a[i - 1] == b[j - 1] ? 0 : 1;
        m[i][j] = [m[i - 1][j] + 1, m[i][j - 1] + 1, m[i - 1][j - 1] + c]
            .reduce((a, b) => a < b ? a : b);
      }
    }
    return m[a.length][b.length];
  }
}

class _TextElement {
  final String text;
  final double centerX;
  final double centerY;
  final double top;
  final double bottom;

  const _TextElement({
    required this.text,
    required this.centerX,
    required this.centerY,
    required this.top,
    required this.bottom,
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
