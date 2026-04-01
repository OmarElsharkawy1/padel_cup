class Team {
  final String id;
  final String name;
  final String groupId;

  const Team({
    required this.id,
    required this.name,
    required this.groupId,
  });

  Team copyWith({String? id, String? name, String? groupId}) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      groupId: groupId ?? this.groupId,
    );
  }
}
