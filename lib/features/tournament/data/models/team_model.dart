import 'package:hive/hive.dart';

import '../../domain/entities/team.dart';

part 'team_model.g.dart';

@HiveType(typeId: 0)
class TeamModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String groupId;

  TeamModel({
    required this.id,
    required this.name,
    required this.groupId,
  });

  factory TeamModel.fromEntity(Team entity) {
    return TeamModel(
      id: entity.id,
      name: entity.name,
      groupId: entity.groupId,
    );
  }

  Team toEntity() {
    return Team(
      id: id,
      name: name,
      groupId: groupId,
    );
  }
}
