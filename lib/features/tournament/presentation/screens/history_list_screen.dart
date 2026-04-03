import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:padel_cup/l10n/generated/app_localizations.dart';

import '../../domain/entities/tournament.dart';
import '../providers/tournament_provider.dart';

class HistoryListScreen extends ConsumerWidget {
  const HistoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final history = ref.watch(tournamentHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tournamentHistory)),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 64,
                      color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(l10n.noHistory,
                      style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final t = history[index];
                return _HistoryCard(tournament: t);
              },
            ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Tournament tournament;

  const _HistoryCard({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateStr = DateFormat('dd/MM/yyyy').format(tournament.createdAt);

    // Get top 3 from finals results
    final podium = _getPodium(tournament);

    return Card(
      child: InkWell(
        onTap: () => context.push('/history/${tournament.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: name + date
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tournament.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Text(
                    dateStr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                  ),
                ],
              ),
              if (podium.isNotEmpty) ...[
                const SizedBox(height: 12),
                // Podium
                for (var i = 0; i < podium.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          size: 18,
                          color: i == 0
                              ? Colors.amber
                              : i == 1
                                  ? Colors.grey.shade400
                                  : Colors.brown.shade300,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          podium[i],
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight:
                                    i == 0 ? FontWeight.bold : null,
                              ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Gets the top 3 team names from a completed tournament.
  List<String> _getPodium(Tournament tournament) {
    final finals = tournament.finalMatches;
    if (finals.length < 2) return [];

    final firstPlaceMatch = finals[0];
    final thirdPlaceMatch = finals[1];

    if (!firstPlaceMatch.isCompleted) return [];

    final names = <String>[];

    // 1st place
    final championId = firstPlaceMatch.team1Sets > firstPlaceMatch.team2Sets
        ? firstPlaceMatch.team1Id
        : firstPlaceMatch.team2Id;
    final champion = tournament.teams.where((t) => t.id == championId).firstOrNull;
    if (champion != null) names.add(champion.name);

    // 2nd place (loser of final)
    final runnerUpId = firstPlaceMatch.team1Sets > firstPlaceMatch.team2Sets
        ? firstPlaceMatch.team2Id
        : firstPlaceMatch.team1Id;
    final runnerUp = tournament.teams.where((t) => t.id == runnerUpId).firstOrNull;
    if (runnerUp != null) names.add(runnerUp.name);

    // 3rd place
    if (thirdPlaceMatch.isCompleted) {
      final thirdId = thirdPlaceMatch.team1Sets > thirdPlaceMatch.team2Sets
          ? thirdPlaceMatch.team1Id
          : thirdPlaceMatch.team2Id;
      final third = tournament.teams.where((t) => t.id == thirdId).firstOrNull;
      if (third != null) names.add(third.name);
    }

    return names;
  }
}
