import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/tournament_local_datasource.dart';
import '../../data/repositories/tournament_repository_impl.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/match.dart';
import '../../domain/entities/standing.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/repositories/tournament_repository.dart';
import '../../domain/usecases/create_tournament.dart';
import '../../domain/usecases/parse_schedule_image.dart';
import '../../domain/usecases/generate_finals.dart';
import '../../domain/usecases/generate_schedule.dart';
import '../../domain/usecases/get_standings.dart';
import '../../domain/usecases/update_match_result.dart';

// Pre-loaded tournament from Hive (set via ProviderScope override in bootstrap)
final initialTournamentProvider = Provider<Tournament?>((_) => null);

// Data source
final tournamentLocalDataSourceProvider =
    Provider<TournamentLocalDataSource>(
  (ref) => TournamentLocalDataSourceImpl(),
);

// Repository
final tournamentRepositoryProvider = Provider<TournamentRepository>(
  (ref) => TournamentRepositoryImpl(
    ref.read(tournamentLocalDataSourceProvider),
  ),
);

// Use cases
final generateScheduleProvider = Provider((_) => const GenerateSchedule());

final createTournamentProvider = Provider(
  (ref) => CreateTournament(
    ref.read(tournamentRepositoryProvider),
    ref.read(generateScheduleProvider),
  ),
);

final updateMatchResultProvider = Provider(
  (ref) => UpdateMatchResult(ref.read(tournamentRepositoryProvider)),
);

final getStandingsProvider = Provider((_) => const GetStandings());

final generateFinalsProvider = Provider(
  (ref) => GenerateFinals(
    ref.read(tournamentRepositoryProvider),
    ref.read(getStandingsProvider),
  ),
);

// Tournament state
final tournamentProvider =
    StateNotifierProvider<TournamentNotifier, Tournament?>(
  (ref) {
    final initial = ref.read(initialTournamentProvider);
    return TournamentNotifier(ref, initial);
  },
);

class TournamentNotifier extends StateNotifier<Tournament?> {
  final Ref _ref;

  TournamentNotifier(this._ref, Tournament? initial) : super(initial);

  Future<void> createTournament({
    required String name,
    required List<String> groupANames,
    required List<String> groupBNames,
    required int matchTimerMinutes,
  }) async {
    final useCase = _ref.read(createTournamentProvider);
    final tournament = await useCase(
      name: name,
      groupANames: groupANames,
      groupBNames: groupBNames,
      matchTimerMinutes: matchTimerMinutes,
    );
    state = tournament;
  }

  /// Creates a tournament from a parsed image schedule with exact matchups.
  Future<void> createTournamentFromImage({
    required String name,
    required ParsedSchedule schedule,
    required int matchTimerMinutes,
  }) async {
    const uuid = Uuid();

    // Create team entities from unique names
    final groupATeams = schedule.groupATeams
        .map((n) => Team(id: uuid.v4(), name: n, groupId: 'A'))
        .toList();
    final groupBTeams = schedule.groupBTeams
        .map((n) => Team(id: uuid.v4(), name: n, groupId: 'B'))
        .toList();

    final allTeams = [...groupATeams, ...groupBTeams];

    // Build name → ID lookup
    final nameToId = <String, String>{};
    for (final t in allTeams) {
      nameToId[t.name] = t.id;
    }

    // Convert parsed matches to TournamentMatch entities
    final matches = <TournamentMatch>[];
    for (final pm in schedule.matches) {
      final t1Id = nameToId[pm.team1Name];
      final t2Id = nameToId[pm.team2Name];
      if (t1Id == null || t2Id == null) continue;

      matches.add(TournamentMatch(
        id: uuid.v4(),
        roundNumber: pm.roundNumber,
        courtNumber: pm.courtNumber,
        team1Id: t1Id,
        team2Id: t2Id,
        groupId: pm.groupId,
      ));
    }

    final tournament = Tournament(
      id: uuid.v4(),
      name: name,
      teams: allTeams,
      matches: matches,
      matchTimerMinutes: matchTimerMinutes,
      status: TournamentStatus.groupStage,
    );

    final repo = _ref.read(tournamentRepositoryProvider);
    await repo.saveTournament(tournament);
    state = tournament;
  }

  Future<void> updateMatchResult({
    required String matchId,
    required int team1Sets,
    required int team2Sets,
  }) async {
    final current = state;
    if (current == null) return;
    final useCase = _ref.read(updateMatchResultProvider);
    final updated = await useCase(
      tournament: current,
      matchId: matchId,
      team1Sets: team1Sets,
      team2Sets: team2Sets,
    );
    state = updated;
  }

  Future<void> generateFinals() async {
    final current = state;
    if (current == null) return;
    final useCase = _ref.read(generateFinalsProvider);
    final updated = await useCase(current);
    state = updated;
  }

  Future<void> resetTournament() async {
    final repo = _ref.read(tournamentRepositoryProvider);
    await repo.deleteTournament();
    state = null;
  }

  Future<void> saveTournament(Tournament tournament) async {
    final repo = _ref.read(tournamentRepositoryProvider);
    await repo.saveTournament(tournament);
    state = tournament;
  }

  /// Replaces the matchups for [roundNumber] in [groupId] with the given
  /// teams, then **regenerates** all subsequent rounds in the same group
  /// to guarantee:
  ///   - each team rests exactly once across all 5 rounds
  ///   - no team plays the same opponent twice
  ///   - each team plays exactly 4 matches
  /// Also removes any generated finals.
  Future<void> editRound({
    required int roundNumber,
    required String groupId,
    required String court1Team1Id,
    required String court1Team2Id,
    required String court2Team1Id,
    required String court2Team2Id,
    required int courtOffset,
  }) async {
    final current = state;
    if (current == null) return;

    final groupTeams = current.teams
        .where((t) => t.groupId == groupId)
        .map((t) => t.id)
        .toList();

    // ── Collect fixed rounds: rounds before the edited one ──
    final fixedMatches = current.matches
        .where((m) =>
            !m.isFinal &&
            m.groupId == groupId &&
            m.roundNumber < roundNumber)
        .toList();

    // Build the constraint sets from fixed rounds
    final usedMatchups = <String>{};  // "id1_id2" (sorted)
    final teamRestRound = <String, int>{};  // teamId -> round it rested

    for (final m in fixedMatches) {
      final pair = _matchupKey(m.team1Id, m.team2Id);
      usedMatchups.add(pair);
    }
    // Find who rested in fixed rounds
    for (var r = 1; r < roundNumber; r++) {
      final roundMs = fixedMatches.where((m) => m.roundNumber == r);
      final playing = <String>{};
      for (final m in roundMs) {
        playing.add(m.team1Id);
        playing.add(m.team2Id);
      }
      for (final tid in groupTeams) {
        if (!playing.contains(tid)) {
          teamRestRound[tid] = r;
        }
      }
    }

    // ── Add the user-edited round ──
    final editedRoundResting = groupTeams.firstWhere((tid) =>
        tid != court1Team1Id &&
        tid != court1Team2Id &&
        tid != court2Team1Id &&
        tid != court2Team2Id);

    usedMatchups.add(_matchupKey(court1Team1Id, court1Team2Id));
    usedMatchups.add(_matchupKey(court2Team1Id, court2Team2Id));
    teamRestRound[editedRoundResting] = roundNumber;

    // Get existing match objects for the edited round to reuse IDs
    final editedRoundOldMatches = current.matches
        .where((m) =>
            !m.isFinal &&
            m.groupId == groupId &&
            m.roundNumber == roundNumber)
        .toList();

    final court1Old = editedRoundOldMatches
        .where((m) => m.courtNumber == courtOffset + 1)
        .firstOrNull;
    final court2Old = editedRoundOldMatches
        .where((m) => m.courtNumber == courtOffset + 2)
        .firstOrNull;

    final editedMatches = <TournamentMatch>[
      (court1Old ?? TournamentMatch(
        id: court1Team1Id, roundNumber: roundNumber,
        courtNumber: courtOffset + 1, team1Id: court1Team1Id,
        team2Id: court1Team2Id, groupId: groupId,
      )).copyWith(
        team1Id: court1Team1Id, team2Id: court1Team2Id,
        team1Sets: 0, team2Sets: 0, isCompleted: false,
      ),
      (court2Old ?? TournamentMatch(
        id: court2Team1Id, roundNumber: roundNumber,
        courtNumber: courtOffset + 2, team1Id: court2Team1Id,
        team2Id: court2Team2Id, groupId: groupId,
      )).copyWith(
        team1Id: court2Team1Id, team2Id: court2Team2Id,
        team1Sets: 0, team2Sets: 0, isCompleted: false,
      ),
    ];

    // ── Regenerate rounds after the edited one ──
    final generatedMatches = <TournamentMatch>[];
    final totalRounds = 5;

    // Get old match objects for subsequent rounds to reuse IDs
    final subsequentOldMatches = current.matches
        .where((m) =>
            !m.isFinal &&
            m.groupId == groupId &&
            m.roundNumber > roundNumber)
        .toList();

    for (var r = roundNumber + 1; r <= totalRounds; r++) {
      // Determine who must rest: a team that hasn't rested yet
      final teamsNotRested =
          groupTeams.where((tid) => !teamRestRound.containsKey(tid)).toList();

      String restingTeam;
      if (teamsNotRested.length == 1) {
        restingTeam = teamsNotRested.first;
      } else if (teamsNotRested.isNotEmpty) {
        // Pick the first available team that hasn't rested
        restingTeam = teamsNotRested.first;
      } else {
        // All have rested (shouldn't happen in 5 rounds / 5 teams), fallback
        restingTeam = groupTeams[r - 1];
      }
      teamRestRound[restingTeam] = r;

      final playing =
          groupTeams.where((tid) => tid != restingTeam).toList();

      // Find a valid pairing: 2 matches from 4 players, no duplicate matchups
      final pairing = _findValidPairing(playing, usedMatchups);

      // Record the matchups
      usedMatchups.add(_matchupKey(pairing[0], pairing[1]));
      usedMatchups.add(_matchupKey(pairing[2], pairing[3]));

      // Reuse old match IDs if available
      final oldRoundMs =
          subsequentOldMatches.where((m) => m.roundNumber == r).toList();
      final oldC1 = oldRoundMs
          .where((m) => m.courtNumber == courtOffset + 1)
          .firstOrNull;
      final oldC2 = oldRoundMs
          .where((m) => m.courtNumber == courtOffset + 2)
          .firstOrNull;

      generatedMatches.add(
        (oldC1 ?? TournamentMatch(
          id: '${groupId}_${r}_1',
          roundNumber: r, courtNumber: courtOffset + 1,
          team1Id: pairing[0], team2Id: pairing[1], groupId: groupId,
        )).copyWith(
          team1Id: pairing[0], team2Id: pairing[1],
          team1Sets: 0, team2Sets: 0, isCompleted: false,
        ),
      );
      generatedMatches.add(
        (oldC2 ?? TournamentMatch(
          id: '${groupId}_${r}_2',
          roundNumber: r, courtNumber: courtOffset + 2,
          team1Id: pairing[2], team2Id: pairing[3], groupId: groupId,
        )).copyWith(
          team1Id: pairing[2], team2Id: pairing[3],
          team1Sets: 0, team2Sets: 0, isCompleted: false,
        ),
      );
    }

    // ── Assemble final match list ──
    final allUpdated = <TournamentMatch>[
      // Other group's matches (untouched)
      ...current.matches.where((m) => !m.isFinal && m.groupId != groupId),
      // This group: fixed rounds
      ...fixedMatches,
      // This group: edited round
      ...editedMatches,
      // This group: regenerated rounds
      ...generatedMatches,
    ];

    final updated = current.copyWith(
      matches: allUpdated,
      status: TournamentStatus.groupStage,
    );

    final repo = _ref.read(tournamentRepositoryProvider);
    await repo.saveTournament(updated);
    state = updated;
  }

  /// Creates a canonical key for a matchup (order-independent).
  static String _matchupKey(String a, String b) {
    return a.compareTo(b) < 0 ? '${a}_$b' : '${b}_$a';
  }

  /// Finds a valid pairing of 4 players into 2 matches,
  /// ensuring no pair is in [usedMatchups].
  /// Returns [p1, p2, p3, p4] where match1 = p1 vs p2, match2 = p3 vs p4.
  static List<String> _findValidPairing(
    List<String> players,
    Set<String> usedMatchups,
  ) {
    assert(players.length == 4);
    // There are only 3 possible ways to pair 4 players:
    // (0v1, 2v3), (0v2, 1v3), (0v3, 1v2)
    final pairings = [
      [0, 1, 2, 3],
      [0, 2, 1, 3],
      [0, 3, 1, 2],
    ];

    for (final p in pairings) {
      final key1 = _matchupKey(players[p[0]], players[p[1]]);
      final key2 = _matchupKey(players[p[2]], players[p[3]]);
      if (!usedMatchups.contains(key1) && !usedMatchups.contains(key2)) {
        return [players[p[0]], players[p[1]], players[p[2]], players[p[3]]];
      }
    }

    // Fallback (should not happen in a valid 5-team round-robin)
    return [players[0], players[1], players[2], players[3]];
  }
}

// Standings providers
final groupAStandingsProvider = Provider<List<Standing>>((ref) {
  final tournament = ref.watch(tournamentProvider);
  if (tournament == null) return [];
  final getStandings = ref.read(getStandingsProvider);
  return getStandings(
    teams: tournament.groupATeams,
    matches: tournament.matches,
  );
});

final groupBStandingsProvider = Provider<List<Standing>>((ref) {
  final tournament = ref.watch(tournamentProvider);
  if (tournament == null) return [];
  final getStandings = ref.read(getStandingsProvider);
  return getStandings(
    teams: tournament.groupBTeams,
    matches: tournament.matches,
  );
});
