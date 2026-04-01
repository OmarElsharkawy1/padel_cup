import '../../../../core/constants/app_constants.dart';
import '../entities/match.dart';
import '../entities/standing.dart';
import '../entities/team.dart';

class GetStandings {
  const GetStandings();

  List<Standing> call({
    required List<Team> teams,
    required List<TournamentMatch> matches,
  }) {
    final standings = <Standing>[];

    for (final team in teams) {
      final teamMatches = matches.where(
        (m) =>
            !m.isFinal &&
            m.isCompleted &&
            (m.team1Id == team.id || m.team2Id == team.id),
      );

      int wins = 0, ties = 0, losses = 0, setsWon = 0, setsLost = 0;

      for (final match in teamMatches) {
        final isTeam1 = match.team1Id == team.id;
        final mySets = isTeam1 ? match.team1Sets : match.team2Sets;
        final oppSets = isTeam1 ? match.team2Sets : match.team1Sets;

        setsWon += mySets;
        setsLost += oppSets;

        if (mySets > oppSets) {
          wins++;
        } else if (mySets == oppSets) {
          ties++;
        } else {
          losses++;
        }
      }

      final points = (wins * AppConstants.winPoints) +
          (ties * AppConstants.tiePoints) +
          (losses * AppConstants.lossPoints);

      standings.add(Standing(
        teamId: team.id,
        teamName: team.name,
        played: teamMatches.length,
        wins: wins,
        ties: ties,
        losses: losses,
        points: points,
        setsWon: setsWon,
        setsLost: setsLost,
      ));
    }

    standings.sort();
    return standings;
  }
}
