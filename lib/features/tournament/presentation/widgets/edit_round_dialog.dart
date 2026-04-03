import 'package:flutter/material.dart';
import 'package:padel_cup/l10n/generated/app_localizations.dart';

import '../../domain/entities/team.dart';

/// Result of editing a round: who rests, and 2 match pairings.
typedef EditRoundResult = ({
  String restingTeamId,
  String court1Team1Id,
  String court1Team2Id,
  String court2Team1Id,
  String court2Team2Id,
});

/// A matchup that already exists in another round.
class ExistingMatchup {
  final String team1Id;
  final String team2Id;
  final int roundNumber;

  const ExistingMatchup({
    required this.team1Id,
    required this.team2Id,
    required this.roundNumber,
  });

  bool matches(String a, String b) =>
      (team1Id == a && team2Id == b) || (team1Id == b && team2Id == a);
}

/// Which team rests in which other round.
class ExistingRest {
  final String teamId;
  final int roundNumber;

  const ExistingRest({required this.teamId, required this.roundNumber});
}

class EditRoundDialog extends StatefulWidget {
  final List<Team> groupTeams;
  final String groupId;
  final int roundNumber;
  final int totalRounds;
  final int courtOffset;
  final List<ExistingMatchup> existingMatchups;
  final List<ExistingRest> existingRests;
  final String? currentRestingId;
  final String? currentCourt1Team1Id;
  final String? currentCourt1Team2Id;
  final String? currentCourt2Team1Id;
  final String? currentCourt2Team2Id;

  const EditRoundDialog({
    super.key,
    required this.groupTeams,
    required this.groupId,
    required this.roundNumber,
    required this.totalRounds,
    required this.courtOffset,
    required this.existingMatchups,
    required this.existingRests,
    this.currentRestingId,
    this.currentCourt1Team1Id,
    this.currentCourt1Team2Id,
    this.currentCourt2Team1Id,
    this.currentCourt2Team2Id,
  });

  @override
  State<EditRoundDialog> createState() => _EditRoundDialogState();
}

class _EditRoundDialogState extends State<EditRoundDialog> {
  String? _restingTeamId;
  String? _court1Team1;
  String? _court1Team2;
  String? _court2Team1;
  String? _court2Team2;

  @override
  void initState() {
    super.initState();
    _restingTeamId = widget.currentRestingId;
    _court1Team1 = widget.currentCourt1Team1Id;
    _court1Team2 = widget.currentCourt1Team2Id;
    _court2Team1 = widget.currentCourt2Team1Id;
    _court2Team2 = widget.currentCourt2Team2Id;
  }

  /// All teams except the resting one.
  List<Team> get _playingTeams =>
      widget.groupTeams.where((t) => t.id != _restingTeamId).toList();

  String _teamName(String id) =>
      widget.groupTeams.firstWhere((t) => t.id == id).name;

  ExistingRest? _restConflict(String teamId) {
    for (final r in widget.existingRests) {
      if (r.teamId == teamId) return r;
    }
    return null;
  }

  ExistingMatchup? _matchupConflict(String? a, String? b) {
    if (a == null || b == null) return null;
    for (final m in widget.existingMatchups) {
      if (m.matches(a, b)) return m;
    }
    return null;
  }

  /// Find teams that appear more than once across the 4 court slots.
  Set<String> get _duplicateTeams {
    final all = [_court1Team1, _court1Team2, _court2Team1, _court2Team2]
        .whereType<String>()
        .toList();
    final seen = <String>{};
    final dupes = <String>{};
    for (final id in all) {
      if (!seen.add(id)) dupes.add(id);
    }
    return dupes;
  }

  /// Check if any court slot uses the resting team.
  bool get _restingTeamInCourt {
    if (_restingTeamId == null) return false;
    return _court1Team1 == _restingTeamId ||
        _court1Team2 == _restingTeamId ||
        _court2Team1 == _restingTeamId ||
        _court2Team2 == _restingTeamId;
  }

  bool get _allSlotsFilled =>
      _restingTeamId != null &&
      _court1Team1 != null &&
      _court1Team2 != null &&
      _court2Team1 != null &&
      _court2Team2 != null;

  bool get _hasErrors {
    if (!_allSlotsFilled) return true;
    if (_duplicateTeams.isNotEmpty) return true;
    if (_restingTeamInCourt) return true;
    if (_restConflict(_restingTeamId!) != null) return true;
    if (_matchupConflict(_court1Team1, _court1Team2) != null) return true;
    if (_matchupConflict(_court2Team1, _court2Team2) != null) return true;
    return false;
  }

  void _onRestingChanged(String? teamId) {
    setState(() => _restingTeamId = teamId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final groupLabel = widget.groupId == 'A' ? l10n.groupA : l10n.groupB;
    final dupes = _duplicateTeams;

    return AlertDialog(
      title: Text('${l10n.editRound} ${widget.roundNumber} — $groupLabel'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Resting team ──
            Text(l10n.resting,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              key: ValueKey('rest_$_restingTeamId'),
              initialValue: _restingTeamId,
              isExpanded: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.airline_seat_recline_normal),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                errorText: _restingTeamId != null &&
                        _restConflict(_restingTeamId!) != null
                    ? l10n.teamAlreadyRested(
                        _restConflict(_restingTeamId!)!.roundNumber)
                    : null,
              ),
              items: widget.groupTeams.map((t) {
                final conflict = _restConflict(t.id);
                return DropdownMenuItem(
                  value: t.id,
                  child: Row(
                    children: [
                      Expanded(child: Text(t.name)),
                      if (conflict != null)
                        Icon(Icons.warning_amber,
                            size: 16, color: colorScheme.error),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _onRestingChanged,
            ),
            const SizedBox(height: 20),

            // ── Court 1 ──
            Text(l10n.court(widget.courtOffset + 1),
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            _buildMatchRow(
              value1: _court1Team1,
              value2: _court1Team2,
              onChanged1: (v) => setState(() => _court1Team1 = v),
              onChanged2: (v) => setState(() => _court1Team2 = v),
              l10n: l10n,
            ),
            ..._buildSlotErrors(
                context, _court1Team1, _court1Team2, dupes, l10n),
            const SizedBox(height: 16),

            // ── Court 2 ──
            Text(l10n.court(widget.courtOffset + 2),
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            _buildMatchRow(
              value1: _court2Team1,
              value2: _court2Team2,
              onChanged1: (v) => setState(() => _court2Team1 = v),
              onChanged2: (v) => setState(() => _court2Team2 = v),
              l10n: l10n,
            ),
            ..._buildSlotErrors(
                context, _court2Team1, _court2Team2, dupes, l10n),

            // ── Cascade warning ──
            if (widget.roundNumber < widget.totalRounds) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.regenerateFrom(
                      widget.roundNumber, widget.totalRounds),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _hasErrors
              ? null
              : () => Navigator.pop<EditRoundResult>(
                    context,
                    (
                      restingTeamId: _restingTeamId!,
                      court1Team1Id: _court1Team1!,
                      court1Team2Id: _court1Team2!,
                      court2Team1Id: _court2Team1!,
                      court2Team2Id: _court2Team2!,
                    ),
                  ),
          child: Text(l10n.confirm),
        ),
      ],
    );
  }

  /// Build error widgets for a court's two slots.
  List<Widget> _buildSlotErrors(
    BuildContext context,
    String? teamA,
    String? teamB,
    Set<String> dupes,
    AppLocalizations l10n,
  ) {
    final errors = <Widget>[];
    final errorColor = Theme.of(context).colorScheme.error;

    // Duplicate team error
    if (teamA != null && dupes.contains(teamA)) {
      errors.add(_errorRow(
        l10n.teamSelectedTwice(_teamName(teamA)),
        errorColor,
      ));
    }
    if (teamB != null && dupes.contains(teamB) && teamB != teamA) {
      errors.add(_errorRow(
        l10n.teamSelectedTwice(_teamName(teamB)),
        errorColor,
      ));
    }

    // Resting team used in court
    if (teamA != null && teamA == _restingTeamId) {
      errors.add(_errorRow(
        l10n.teamAlreadyRested(widget.roundNumber),
        errorColor,
      ));
    }
    if (teamB != null && teamB == _restingTeamId && teamB != teamA) {
      errors.add(_errorRow(
        l10n.teamAlreadyRested(widget.roundNumber),
        errorColor,
      ));
    }

    // Matchup conflict with previous rounds
    final conflict = _matchupConflict(teamA, teamB);
    if (conflict != null) {
      errors.add(_errorRow(
        l10n.matchupAlreadyExists(
          _teamName(conflict.team1Id),
          _teamName(conflict.team2Id),
          conflict.roundNumber,
        ),
        errorColor,
      ));
    }

    return errors;
  }

  Widget _errorRow(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 14, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 12, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchRow({
    required String? value1,
    required String? value2,
    required ValueChanged<String?> onChanged1,
    required ValueChanged<String?> onChanged2,
    required AppLocalizations l10n,
  }) {
    // Show ALL playing teams in every dropdown — no filtering
    final teams = _playingTeams;

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            key: ValueKey('c_${value1}_$_restingTeamId'),
            initialValue: teams.any((t) => t.id == value1) ? value1 : null,
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: teams
                .map((t) => DropdownMenuItem(
                      value: t.id,
                      child: Text(t.name, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: onChanged1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(l10n.vs,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: DropdownButtonFormField<String>(
            key: ValueKey('c_${value2}_$_restingTeamId'),
            initialValue: teams.any((t) => t.id == value2) ? value2 : null,
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: teams
                .map((t) => DropdownMenuItem(
                      value: t.id,
                      child: Text(t.name, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: onChanged2,
          ),
        ),
      ],
    );
  }
}
