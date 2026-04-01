import 'package:hive/hive.dart';

import '../../domain/entities/tournament.dart';
import 'match_model.dart';
import 'team_model.dart';

part 'tournament_model.g.dart';

@HiveType(typeId: 2)
class TournamentModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final List<TeamModel> teams;

  @HiveField(3)
  final List<MatchModel> matches;

  @HiveField(4)
  final int matchTimerMinutes;

  @HiveField(5)
  final int statusIndex;

  TournamentModel({
    required this.id,
    required this.name,
    required this.teams,
    required this.matches,
    required this.matchTimerMinutes,
    required this.statusIndex,
  });

  factory TournamentModel.fromEntity(Tournament entity) {
    return TournamentModel(
      id: entity.id,
      name: entity.name,
      teams: entity.teams.map((t) => TeamModel.fromEntity(t)).toList(),
      matches:
          entity.matches.map((m) => MatchModel.fromEntity(m)).toList(),
      matchTimerMinutes: entity.matchTimerMinutes,
      statusIndex: entity.status.index,
    );
  }

  Tournament toEntity() {
    return Tournament(
      id: id,
      name: name,
      teams: teams.map((t) => t.toEntity()).toList(),
      matches: matches.map((m) => m.toEntity()).toList(),
      matchTimerMinutes: matchTimerMinutes,
      status: TournamentStatus.values[statusIndex],
    );
  }
}
