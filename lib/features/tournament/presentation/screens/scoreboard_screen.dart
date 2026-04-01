import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padel_cup/l10n/generated/app_localizations.dart';

import '../../domain/entities/match.dart';
import '../../domain/entities/tournament.dart';
import '../providers/tournament_provider.dart';
import '../widgets/match_score_dialog.dart';

class ScoreboardScreen extends ConsumerWidget {
  const ScoreboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tournamentAsync = ref.watch(tournamentProvider);

    return tournamentAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (tournament) {
        if (tournament == null) {
          return Center(child: Text(l10n.noTournament));
        }
        return _ScoreboardContent(tournament: tournament);
      },
    );
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
                Text(
                  l10n.round(roundNum),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
