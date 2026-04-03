import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padel_cup/l10n/generated/app_localizations.dart';

import '../../domain/entities/match.dart';
import '../../domain/entities/tournament.dart';
import '../providers/tournament_provider.dart';
import '../widgets/edit_round_dialog.dart';
import '../widgets/match_score_dialog.dart';

class ScoreboardScreen extends ConsumerWidget {
  const ScoreboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tournament = ref.watch(tournamentProvider);

    if (tournament == null) {
      return Center(child: Text(l10n.noTournament));
    }
    return _ScoreboardContent(tournament: tournament);
  }
}

class _ScoreboardContent extends ConsumerWidget {
  final Tournament tournament;

  const _ScoreboardContent({required this.tournament});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isWide = MediaQuery.sizeOf(context).width > 600;
    final groupMatches = tournament.groupMatches;

    // Organize by round
    final rounds = <int, List<TournamentMatch>>{};
    for (final match in groupMatches) {
      rounds.putIfAbsent(match.roundNumber, () => []).add(match);
    }

    final sortedRounds = rounds.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: sortedRounds.length,
      itemBuilder: (context, index) {
        final roundNum = sortedRounds[index];
        final roundMatches = rounds[roundNum]!;

        // Group matches by group
        final groupAMatches =
            roundMatches.where((m) => m.groupId == 'A').toList();
        final groupBMatches =
            roundMatches.where((m) => m.groupId == 'B').toList();

        // Find resting teams
        final restingA = _findRestingTeam(tournament, 'A', roundNum);
        final restingB = _findRestingTeam(tournament, 'B', roundNum);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.round(roundNum),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_calendar, size: 20),
                      tooltip: l10n.editRound,
                      onPressed: () => _showEditRoundDialog(
                        context, ref, tournament, roundNum,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildGroupRound(
                          context, ref, l10n.groupA, groupAMatches, restingA, tournament, ref,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildGroupRound(
                          context, ref, l10n.groupB, groupBMatches, restingB, tournament, ref,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildGroupRound(
                    context, ref, l10n.groupA, groupAMatches, restingA, tournament, ref,
                  ),
                  const SizedBox(height: 8),
                  _buildGroupRound(
                    context, ref, l10n.groupB, groupBMatches, restingB, tournament, ref,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditRoundDialog(
    BuildContext context,
    WidgetRef ref,
    Tournament tournament,
    int roundNumber,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    // Let user pick which group to edit
    final groupId = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('${l10n.editRound} ${roundNumber}'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'A'),
            child: Text(l10n.groupA),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'B'),
            child: Text(l10n.groupB),
          ),
        ],
      ),
    );
    if (groupId == null || !context.mounted) return;

    final groupTeams =
        tournament.teams.where((t) => t.groupId == groupId).toList();
    final courtOffset = groupId == 'A' ? 0 : 2;

    // Gather all group matches for this group
    final allGroupMatches = tournament.groupMatches
        .where((m) => m.groupId == groupId)
        .toList();

    // Current round's matchups
    final roundMatches =
        allGroupMatches.where((m) => m.roundNumber == roundNumber).toList();

    final court1Match = roundMatches
        .where((m) => m.courtNumber == courtOffset + 1)
        .firstOrNull;
    final court2Match = roundMatches
        .where((m) => m.courtNumber == courtOffset + 2)
        .firstOrNull;

    // Find resting team for current round
    final playingIds = <String>{};
    for (final m in roundMatches) {
      playingIds.add(m.team1Id);
      playingIds.add(m.team2Id);
    }
    final restingId = groupTeams
        .where((t) => !playingIds.contains(t.id))
        .map((t) => t.id)
        .firstOrNull;

    // Build existing matchups from OTHER rounds (before the edited one only,
    // since rounds after will be cleared)
    final existingMatchups = <ExistingMatchup>[];
    final existingRests = <ExistingRest>[];

    for (var r = 1; r <= 5; r++) {
      if (r == roundNumber) continue; // skip the round being edited
      if (r > roundNumber) continue; // rounds after will be cleared

      final otherRoundMatches =
          allGroupMatches.where((m) => m.roundNumber == r).toList();

      for (final m in otherRoundMatches) {
        existingMatchups.add(ExistingMatchup(
          team1Id: m.team1Id,
          team2Id: m.team2Id,
          roundNumber: r,
        ));
      }

      // Find resting team in this other round
      final otherPlayingIds = <String>{};
      for (final m in otherRoundMatches) {
        otherPlayingIds.add(m.team1Id);
        otherPlayingIds.add(m.team2Id);
      }
      for (final t in groupTeams) {
        if (!otherPlayingIds.contains(t.id)) {
          existingRests.add(ExistingRest(teamId: t.id, roundNumber: r));
        }
      }
    }

    final result = await showDialog<EditRoundResult>(
      context: context,
      builder: (_) => EditRoundDialog(
        groupTeams: groupTeams,
        groupId: groupId,
        roundNumber: roundNumber,
        totalRounds: 5,
        courtOffset: courtOffset,
        existingMatchups: existingMatchups,
        existingRests: existingRests,
        currentRestingId: restingId,
        currentCourt1Team1Id: court1Match?.team1Id,
        currentCourt1Team2Id: court1Match?.team2Id,
        currentCourt2Team1Id: court2Match?.team1Id,
        currentCourt2Team2Id: court2Match?.team2Id,
      ),
    );

    if (result != null) {
      ref.read(tournamentProvider.notifier).editRound(
            roundNumber: roundNumber,
            groupId: groupId,
            court1Team1Id: result.court1Team1Id,
            court1Team2Id: result.court1Team2Id,
            court2Team1Id: result.court2Team1Id,
            court2Team2Id: result.court2Team2Id,
            courtOffset: courtOffset,
          );
    }
  }

  String? _findRestingTeam(Tournament tournament, String groupId, int round) {
    final groupTeams =
        tournament.teams.where((t) => t.groupId == groupId).toList();
    final roundMatches = tournament.groupMatches
        .where((m) => m.groupId == groupId && m.roundNumber == round);

    final playingIds = <String>{};
    for (final m in roundMatches) {
      playingIds.add(m.team1Id);
      playingIds.add(m.team2Id);
    }

    for (final team in groupTeams) {
      if (!playingIds.contains(team.id)) {
        return team.name;
      }
    }
    return null;
  }

  Widget _buildGroupRound(
    BuildContext context,
    WidgetRef ref,
    String groupTitle,
    List<TournamentMatch> matches,
    String? restingTeam,
    Tournament tournament,
    WidgetRef widgetRef,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          groupTitle,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
              ),
        ),
        const SizedBox(height: 4),
        for (final match in matches)
          _MatchTile(
            match: match,
            tournament: tournament,
            onTap: () => _showScoreDialog(context, ref, match, tournament),
          ),
        if (restingTeam != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(Icons.airline_seat_recline_normal,
                    size: 16, color: colorScheme.outline),
                const SizedBox(width: 4),
                Text(
                  '${l10n.resting}: $restingTeam',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _showScoreDialog(
    BuildContext context,
    WidgetRef ref,
    TournamentMatch match,
    Tournament tournament,
  ) async {
    final team1 = tournament.teams.firstWhere((t) => t.id == match.team1Id);
    final team2 = tournament.teams.firstWhere((t) => t.id == match.team2Id);

    final result = await showDialog<({int team1Sets, int team2Sets})>(
      context: context,
      builder: (_) => MatchScoreDialog(
        team1Name: team1.name,
        team2Name: team2.name,
        initialTeam1Sets: match.team1Sets,
        initialTeam2Sets: match.team2Sets,
      ),
    );

    if (result != null) {
      ref.read(tournamentProvider.notifier).updateMatchResult(
            matchId: match.id,
            team1Sets: result.team1Sets,
            team2Sets: result.team2Sets,
          );
    }
  }
}

class _MatchTile extends StatelessWidget {
  final TournamentMatch match;
  final Tournament tournament;
  final VoidCallback? onTap;

  const _MatchTile({
    required this.match,
    required this.tournament,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final team1 = tournament.teams.firstWhere((t) => t.id == match.team1Id);
    final team2 = tournament.teams.firstWhere((t) => t.id == match.team2Id);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                team1.name,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: match.isCompleted && match.team1Sets > match.team2Sets
                          ? FontWeight.bold
                          : null,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: match.isCompleted
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                match.isCompleted
                    ? '${match.team1Sets} - ${match.team2Sets}'
                    : l10n.vs,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: match.isCompleted
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Text(
                team2.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: match.isCompleted && match.team2Sets > match.team1Sets
                          ? FontWeight.bold
                          : null,
                    ),
              ),
            ),
            Icon(Icons.edit, size: 16, color: colorScheme.outline),
          ],
        ),
      ),
    );
  }
}
