import 'package:uuid/uuid.dart';

import '../entities/match.dart';
import '../entities/team.dart';

class GenerateSchedule {
  const GenerateSchedule();

  /// Generates round-robin schedule for a group of 5 teams.
  /// Each team plays 4 matches and rests exactly once.
  /// Returns 5 rounds, each with 2 matches.
  ///
  /// Fixed schedule for indices 0-4:
  /// Round 1: (0v1, 2v3, rest=4)
  /// Round 2: (0v2, 1v4, rest=3)
  /// Round 3: (0v3, 2v4, rest=1)
  /// Round 4: (0v4, 1v3, rest=2)
  /// Round 5: (1v2, 3v4, rest=0)
  List<TournamentMatch> call({
    required List<Team> teams,
    required String groupId,
    required int courtOffset,
  }) {
    assert(teams.length == 5);
    const uuid = Uuid();

    final schedule = [
      [0, 1, 2, 3, 4], // round 1: 0v1, 2v3, rest=4
      [0, 2, 1, 4, 3], // round 2: 0v2, 1v4, rest=3
      [0, 3, 2, 4, 1], // round 3: 0v3, 2v4, rest=1
      [0, 4, 1, 3, 2], // round 4: 0v4, 1v3, rest=2
      [1, 2, 3, 4, 0], // round 5: 1v2, 3v4, rest=0
    ];

    final matches = <TournamentMatch>[];

    for (var round = 0; round < schedule.length; round++) {
      final s = schedule[round];
      // Match 1: s[0] vs s[1]
      matches.add(TournamentMatch(
        id: uuid.v4(),
        roundNumber: round + 1,
        courtNumber: courtOffset + 1,
        team1Id: teams[s[0]].id,
        team2Id: teams[s[1]].id,
        groupId: groupId,
      ));
      // Match 2: s[2] vs s[3]
      matches.add(TournamentMatch(
        id: uuid.v4(),
        roundNumber: round + 1,
        courtNumber: courtOffset + 2,
        team1Id: teams[s[2]].id,
        team2Id: teams[s[3]].id,
        groupId: groupId,
      ));
    }

    return matches;
  }
}
