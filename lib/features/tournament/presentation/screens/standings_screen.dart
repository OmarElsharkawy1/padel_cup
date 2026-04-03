import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padel_cup/l10n/generated/app_localizations.dart';

import '../../domain/entities/standing.dart';
import '../providers/tournament_provider.dart';

class StandingsScreen extends ConsumerWidget {
  const StandingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tournament = ref.watch(tournamentProvider);

    if (tournament == null) {
      return Center(child: Text(l10n.noTournament));
    }

    final standingsA = ref.watch(groupAStandingsProvider);
    final standingsB = ref.watch(groupBStandingsProvider);
    final isWide = MediaQuery.sizeOf(context).width > 600;

    if (isWide) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _StandingsTable(
                title: l10n.groupA,
                standings: standingsA,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StandingsTable(
                title: l10n.groupB,
                standings: standingsB,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        _StandingsTable(title: l10n.groupA, standings: standingsA),
        const SizedBox(height: 8),
        _StandingsTable(title: l10n.groupB, standings: standingsB),
      ],
    );
  }
}

class _StandingsTable extends StatelessWidget {
  final String title;
  final List<Standing> standings;

  const _StandingsTable({
    required this.title,
    required this.standings,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 44,
                columnSpacing: 12,
                columns: [
                  DataColumn(label: Text(l10n.rank)),
                  DataColumn(label: Text(l10n.team)),
                  DataColumn(label: Text(l10n.played), numeric: true),
                  DataColumn(label: Text(l10n.wins), numeric: true),
                  DataColumn(label: Text(l10n.ties), numeric: true),
                  DataColumn(label: Text(l10n.losses), numeric: true),
                  DataColumn(label: Text(l10n.setsWon), numeric: true),
                  DataColumn(label: Text(l10n.setsLost), numeric: true),
                  DataColumn(label: Text(l10n.setDifference), numeric: true),
                  DataColumn(label: Text(l10n.points), numeric: true),
                ],
                rows: [
                  for (var i = 0; i < standings.length; i++)
                    DataRow(
                      color: i < 2
                          ? WidgetStatePropertyAll(
                              colorScheme.primaryContainer.withValues(alpha: 0.3),
                            )
                          : null,
                      cells: [
                        DataCell(Text('${i + 1}')),
                        DataCell(Text(
                          standings[i].teamName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        )),
                        DataCell(Text('${standings[i].played}')),
                        DataCell(Text('${standings[i].wins}')),
                        DataCell(Text('${standings[i].ties}')),
                        DataCell(Text('${standings[i].losses}')),
                        DataCell(Text('${standings[i].setsWon}')),
                        DataCell(Text('${standings[i].setsLost}')),
                        DataCell(Text(
                          '${standings[i].setDifference}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: standings[i].setDifference > 0
                                ? Colors.green
                                : standings[i].setDifference < 0
                                    ? Colors.red
                                    : null,
                          ),
                        )),
                        DataCell(Text(
                          '${standings[i].points}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
