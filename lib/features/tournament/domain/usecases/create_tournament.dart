import 'package:uuid/uuid.dart';

import '../entities/team.dart';
import '../entities/tournament.dart';
import '../repositories/tournament_repository.dart';
import 'generate_schedule.dart';

class CreateTournament {
  final TournamentRepository _repository;
  final GenerateSchedule _generateSchedule;

  const CreateTournament(this._repository, this._generateSchedule);

  Future<Tournament> call({
    required String name,
    required List<String> groupANames,
    required List<String> groupBNames,
    required int matchTimerMinutes,
  }) async {
    const uuid = Uuid();

    final groupATeams = groupANames
        .map((n) => Team(id: uuid.v4(), name: n, groupId: 'A'))
        .toList();
    final groupBTeams = groupBNames
        .map((n) => Team(id: uuid.v4(), name: n, groupId: 'B'))
        .toList();

    final groupAMatches = _generateSchedule(
      teams: groupATeams,
      groupId: 'A',
      courtOffset: 0,
    );
    final groupBMatches = _generateSchedule(
      teams: groupBTeams,
      groupId: 'B',
      courtOffset: 2,
    );

    final tournament = Tournament(
      id: uuid.v4(),
      name: name,
      teams: [...groupATeams, ...groupBTeams],
      matches: [...groupAMatches, ...groupBMatches],
      matchTimerMinutes: matchTimerMinutes,
      status: TournamentStatus.groupStage,
    );

    await _repository.saveTournament(tournament);
    return tournament;
  }
}
