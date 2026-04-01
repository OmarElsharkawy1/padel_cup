import 'package:uuid/uuid.dart';

import '../entities/match.dart';
import '../entities/tournament.dart';
import '../repositories/tournament_repository.dart';
import 'get_standings.dart';

class GenerateFinals {
  final TournamentRepository _repository;
  final GetStandings _getStandings;

  const GenerateFinals(this._repository, this._getStandings);

  Future<Tournament> call(Tournament tournament) async {
    // Already has finals
    if (tournament.finalMatches.isNotEmpty) return tournament;

    const uuid = Uuid();

    final standingsA = _getStandings(
      teams: tournament.groupATeams,
      matches: tournament.matches,
    );
    final standingsB = _getStandings(
      teams: tournament.groupBTeams,
      matches: tournament.matches,
    );

    final firstA = standingsA[0];
    final secondA = standingsA[1];
    final firstB = standingsB[0];
    final secondB = standingsB[1];

    final finalMatches = [
      // 1st place match: Winner A vs Winner B
      TournamentMatch(
        id: uuid.v4(),
        roundNumber: 1,
        courtNumber: 1,
        team1Id: firstA.teamId,
        team2Id: firstB.teamId,
        groupId: 'F',
        isFinal: true,
      ),
      // 3rd place match: 2nd A vs 2nd B
      TournamentMatch(
        id: uuid.v4(),
        roundNumber: 1,
        courtNumber: 2,
        team1Id: secondA.teamId,
        team2Id: secondB.teamId,
        groupId: 'F',
        isFinal: true,
      ),
    ];

    final updated = tournament.copyWith(
      matches: [...tournament.matches, ...finalMatches],
      status: TournamentStatus.finals,
    );

    await _repository.saveTournament(updated);
    return updated;
  }
}
