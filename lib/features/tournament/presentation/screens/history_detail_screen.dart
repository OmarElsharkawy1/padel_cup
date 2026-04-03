import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:padel_cup/l10n/generated/app_localizations.dart';

import '../../domain/entities/match.dart';
import '../../domain/entities/standing.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/usecases/get_standings.dart';
import '../providers/tournament_provider.dart';

class HistoryDetailScreen extends ConsumerWidget {
  final String tournamentId;

  const HistoryDetailScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(tournamentHistoryProvider);
    final tournament = history.where((t) => t.id == tournamentId).firstOrNull;

    if (tournament == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Tournament not found')),
      );
    }

    final dateStr = DateFormat('dd/MM/yyyy').format(tournament.createdAt);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tournament.name,
                  style: const TextStyle(fontSize: 16)),
              Text(dateStr,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6))),
            ],
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: AppLocalizations.of(context)!.scoreboard),
              Tab(text: AppLocalizations.of(context)!.standings),
              Tab(text: AppLocalizations.of(context)!.finals),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ScoreboardTab(tournament: tournament),
            _StandingsTab(tournament: tournament),
            _FinalsTab(tournament: tournament),
          ],
        ),
      ),
    );
  }
}

// ── Scoreboard Tab (read-only) ──

class _ScoreboardTab extends StatelessWidget {
  final Tournament tournament;

  const _ScoreboardTab({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWide = MediaQuery.sizeOf(context).width > 600;
    final groupMatches = tournament.groupMatches;

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
        final groupAMatches =
            roundMatches.where((m) => m.groupId == 'A').toList();
        final groupBMatches =
            roundMatches.where((m) => m.groupId == 'B').toList();
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
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Divider(),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: _buildGroup(
                              context, l10n.groupA, groupAMatches,
                              restingA, tournament)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildGroup(
                              context, l10n.groupB, groupBMatches,
                              restingB, tournament)),
                    ],
                  )
                else ...[
                  _buildGroup(context, l10n.groupA, groupAMatches,
                      restingA, tournament),
                  const SizedBox(height: 8),
                  _buildGroup(context, l10n.groupB, groupBMatches,
                      restingB, tournament),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String? _findRestingTeam(
      Tournament tournament, String groupId, int round) {
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
      if (!playingIds.contains(team.id)) return team.name;
    }
    return null;
  }

  Widget _buildGroup(
    BuildContext context,
    String title,
    List<TournamentMatch> matches,
    String? restingTeam,
    Tournament tournament,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: colorScheme.primary)),
        const SizedBox(height: 4),
        for (final match in matches)
          _ReadOnlyMatchTile(match: match, tournament: tournament),
        if (restingTeam != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(Icons.airline_seat_recline_normal,
                    size: 16, color: colorScheme.outline),
                const SizedBox(width: 4),
                Text('${l10n.resting}: $restingTeam',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colorScheme.outline)),
              ],
            ),
          ),
      ],
    );
  }
}

class _ReadOnlyMatchTile extends StatelessWidget {
  final TournamentMatch match;
  final Tournament tournament;

  const _ReadOnlyMatchTile({required this.match, required this.tournament});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final team1 = tournament.teams.firstWhere((t) => t.id == match.team1Id);
    final team2 = tournament.teams.firstWhere((t) => t.id == match.team2Id);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              team1.name,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        match.isCompleted && match.team1Sets > match.team2Sets
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
                    fontWeight:
                        match.isCompleted && match.team2Sets > match.team1Sets
                            ? FontWeight.bold
                            : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Standings Tab ──

class _StandingsTab extends StatelessWidget {
  final Tournament tournament;

  const _StandingsTab({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const getStandings = GetStandings();
    final standingsA = getStandings(
        teams: tournament.groupATeams, matches: tournament.matches);
    final standingsB = getStandings(
        teams: tournament.groupBTeams, matches: tournament.matches);
    final isWide = MediaQuery.sizeOf(context).width > 600;

    if (isWide) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _StandingsTable(title: l10n.groupA, standings: standingsA)),
            const SizedBox(width: 8),
            Expanded(child: _StandingsTable(title: l10n.groupB, standings: standingsB)),
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

  const _StandingsTable({required this.title, required this.standings});

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
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: colorScheme.primary)),
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
                              colorScheme.primaryContainer
                                  .withValues(alpha: 0.3))
                          : null,
                      cells: [
                        DataCell(Text('${i + 1}')),
                        DataCell(Text(standings[i].teamName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500))),
                        DataCell(Text('${standings[i].played}')),
                        DataCell(Text('${standings[i].wins}')),
                        DataCell(Text('${standings[i].ties}')),
                        DataCell(Text('${standings[i].losses}')),
                        DataCell(Text('${standings[i].setsWon}')),
                        DataCell(Text('${standings[i].setsLost}')),
                        DataCell(Text('${standings[i].setDifference}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: standings[i].setDifference > 0
                                  ? Colors.green
                                  : standings[i].setDifference < 0
                                      ? Colors.red
                                      : null,
                            ))),
                        DataCell(Text('${standings[i].points}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold))),
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

// ── Finals Tab ──

class _FinalsTab extends StatelessWidget {
  final Tournament tournament;

  const _FinalsTab({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final finals = tournament.finalMatches;

    if (finals.isEmpty) {
      return Center(child: Text(l10n.finalsNotReady));
    }

    final firstPlaceMatch = finals[0];
    final thirdPlaceMatch = finals.length > 1 ? finals[1] : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ReadOnlyFinalCard(
          title: l10n.firstPlaceMatch,
          match: firstPlaceMatch,
          tournament: tournament,
          icon: Icons.emoji_events,
          iconColor: Colors.amber,
        ),
        const SizedBox(height: 16),
        if (thirdPlaceMatch != null)
          _ReadOnlyFinalCard(
            title: l10n.thirdPlaceMatch,
            match: thirdPlaceMatch,
            tournament: tournament,
            icon: Icons.military_tech,
            iconColor: Colors.brown.shade300,
          ),
      ],
    );
  }
}

class _ReadOnlyFinalCard extends StatelessWidget {
  final String title;
  final TournamentMatch match;
  final Tournament tournament;
  final IconData icon;
  final Color iconColor;

  const _ReadOnlyFinalCard({
    required this.title,
    required this.match,
    required this.tournament,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final team1 = tournament.teams.firstWhere((t) => t.id == match.team1Id);
    final team2 = tournament.teams.firstWhere((t) => t.id == match.team2Id);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 8),
                Text(title,
                    style: Theme.of(context).textTheme.titleLarge),
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
                          fontWeight: match.isCompleted &&
                                  match.team1Sets > match.team2Sets
                              ? FontWeight.bold
                              : null,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
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
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    team2.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: match.isCompleted &&
                                  match.team2Sets > match.team1Sets
                              ? FontWeight.bold
                              : null,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
