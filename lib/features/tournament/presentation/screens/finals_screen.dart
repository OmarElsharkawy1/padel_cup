import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padel_cup/l10n/generated/app_localizations.dart';

import '../../domain/entities/match.dart';
import '../../domain/entities/tournament.dart';
import '../providers/tournament_provider.dart';
import '../widgets/match_score_dialog.dart';

class FinalsScreen extends ConsumerWidget {
  const FinalsScreen({super.key});

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

        if (!tournament.allGroupMatchesCompleted) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.finalsNotReady,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          );
        }

        // Generate finals if not yet generated
        if (tournament.finalMatches.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(tournamentProvider.notifier).generateFinals();
          });
          return const Center(child: CircularProgressIndicator());
        }

        return _FinalsContent(tournament: tournament);
      },
    );
  }
}

class _FinalsContent extends ConsumerWidget {
  final Tournament tournament;

  const _FinalsContent({required this.tournament});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final finals = tournament.finalMatches;

    // First match is 1st place, second is 3rd place
    final firstPlaceMatch = finals.isNotEmpty ? finals[0] : null;
    final thirdPlaceMatch = finals.length > 1 ? finals[1] : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (tournament.status == TournamentStatus.completed)
          _buildChampionBanner(context, tournament),
        if (firstPlaceMatch != null)
          _FinalMatchCard(
            title: l10n.firstPlaceMatch,
            match: firstPlaceMatch,
            tournament: tournament,
            icon: Icons.emoji_events,
            iconColor: Colors.amber,
          ),
        const SizedBox(height: 16),
        if (thirdPlaceMatch != null)
          _FinalMatchCard(
            title: l10n.thirdPlaceMatch,
            match: thirdPlaceMatch,
            tournament: tournament,
            icon: Icons.military_tech,
            iconColor: Colors.brown.shade300,
          ),
      ],
    );
  }

  Widget _buildChampionBanner(BuildContext context, Tournament tournament) {
    final l10n = AppLocalizations.of(context)!;
    final finalMatch = tournament.finalMatches[0];
    final winnerId = finalMatch.team1Sets > finalMatch.team2Sets
        ? finalMatch.team1Id
        : finalMatch.team2Id;
    final winner = tournament.teams.firstWhere((t) => t.id == winnerId);

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.emoji_events, size: 48, color: Colors.amber),
            const SizedBox(height: 8),
            Text(
              l10n.champion,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              winner.name,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinalMatchCard extends ConsumerWidget {
  final String title;
  final TournamentMatch match;
  final Tournament tournament;
  final IconData icon;
  final Color iconColor;

  const _FinalMatchCard({
    required this.title,
    required this.match,
    required this.tournament,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final team1 = tournament.teams.firstWhere((t) => t.id == match.team1Id);
    final team2 = tournament.teams.firstWhere((t) => t.id == match.team2Id);

    return Card(
      child: InkWell(
        onTap: match.isCompleted
            ? null
            : () async {
                final result =
                    await showDialog<({int team1Sets, int team2Sets})>(
                  context: context,
                  builder: (_) => MatchScoreDialog(
                    team1Name: team1.name,
                    team2Name: team2.name,
                  ),
                );
                if (result != null) {
                  ref.read(tournamentProvider.notifier).updateMatchResult(
                        matchId: match.id,
                        team1Sets: result.team1Sets,
                        team2Sets: result.team2Sets,
                      );
                }
              },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: iconColor),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      team1.name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight:
                                match.isCompleted && match.team1Sets > match.team2Sets
                                    ? FontWeight.bold
                                    : null,
                          ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: match.isCompleted
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      match.isCompleted
                          ? '${match.team1Sets} - ${match.team2Sets}'
                          : l10n.vs,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      team2.name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight:
                                match.isCompleted && match.team2Sets > match.team1Sets
                                    ? FontWeight.bold
                                    : null,
                          ),
                    ),
                  ),
                ],
              ),
              if (!match.isCompleted) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.enterScore,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
