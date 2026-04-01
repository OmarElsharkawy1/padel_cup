import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/tournament_local_datasource.dart';
import '../../data/repositories/tournament_repository_impl.dart';
import '../../domain/entities/standing.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/repositories/tournament_repository.dart';
import '../../domain/usecases/create_tournament.dart';
import '../../domain/usecases/generate_finals.dart';
import '../../domain/usecases/generate_schedule.dart';
import '../../domain/usecases/get_standings.dart';
import '../../domain/usecases/update_match_result.dart';

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
    StateNotifierProvider<TournamentNotifier, AsyncValue<Tournament?>>(
  (ref) => TournamentNotifier(ref),
);

class TournamentNotifier extends StateNotifier<AsyncValue<Tournament?>> {
  final Ref _ref;

  TournamentNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(tournamentRepositoryProvider);
      final tournament = await repo.getTournament();
      state = AsyncValue.data(tournament);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createTournament({
    required String name,
    required List<String> groupANames,
    required List<String> groupBNames,
    required int matchTimerMinutes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final useCase = _ref.read(createTournamentProvider);
      final tournament = await useCase(
        name: name,
        groupANames: groupANames,
        groupBNames: groupBNames,
        matchTimerMinutes: matchTimerMinutes,
      );
      state = AsyncValue.data(tournament);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateMatchResult({
    required String matchId,
    required int team1Sets,
    required int team2Sets,
  }) async {
    final current = state.value;
    if (current == null) return;
    try {
      final useCase = _ref.read(updateMatchResultProvider);
      final updated = await useCase(
        tournament: current,
        matchId: matchId,
        team1Sets: team1Sets,
        team2Sets: team2Sets,
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> generateFinals() async {
    final current = state.value;
    if (current == null) return;
    try {
      final useCase = _ref.read(generateFinalsProvider);
      final updated = await useCase(current);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> resetTournament() async {
    try {
      final repo = _ref.read(tournamentRepositoryProvider);
      await repo.deleteTournament();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Standings providers
final groupAStandingsProvider = Provider<List<Standing>>((ref) {
  final tournament = ref.watch(tournamentProvider).value;
  if (tournament == null) return [];
  final getStandings = ref.read(getStandingsProvider);
  return getStandings(
    teams: tournament.groupATeams,
    matches: tournament.matches,
  );
});

final groupBStandingsProvider = Provider<List<Standing>>((ref) {
  final tournament = ref.watch(tournamentProvider).value;
  if (tournament == null) return [];
  final getStandings = ref.read(getStandingsProvider);
  return getStandings(
    teams: tournament.groupBTeams,
    matches: tournament.matches,
  );
});
