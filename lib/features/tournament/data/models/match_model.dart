import 'package:hive/hive.dart';

import '../../domain/entities/match.dart';

part 'match_model.g.dart';

@HiveType(typeId: 1)
class MatchModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int roundNumber;

  @HiveField(2)
  final int courtNumber;

  @HiveField(3)
  final String team1Id;

  @HiveField(4)
  final String team2Id;

  @HiveField(5)
  final int team1Sets;

  @HiveField(6)
  final int team2Sets;

  @HiveField(7)
  final bool isCompleted;

  @HiveField(8)
  final String groupId;

  @HiveField(9)
  final bool isFinal;

  MatchModel({
    required this.id,
    required this.roundNumber,
    required this.courtNumber,
    required this.team1Id,
    required this.team2Id,
    required this.team1Sets,
    required this.team2Sets,
    required this.isCompleted,
    required this.groupId,
    required this.isFinal,
  });

  factory MatchModel.fromEntity(TournamentMatch entity) {
    return MatchModel(
      id: entity.id,
      roundNumber: entity.roundNumber,
      courtNumber: entity.courtNumber,
      team1Id: entity.team1Id,
      team2Id: entity.team2Id,
      team1Sets: entity.team1Sets,
      team2Sets: entity.team2Sets,
      isCompleted: entity.isCompleted,
      groupId: entity.groupId,
      isFinal: entity.isFinal,
    );
  }

  TournamentMatch toEntity() {
    return TournamentMatch(
      id: id,
      roundNumber: roundNumber,
      courtNumber: courtNumber,
      team1Id: team1Id,
      team2Id: team2Id,
      team1Sets: team1Sets,
      team2Sets: team2Sets,
      isCompleted: isCompleted,
      groupId: groupId,
      isFinal: isFinal,
    );
  }
}
