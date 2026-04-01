class TournamentMatch {
  final String id;
  final int roundNumber;
  final int courtNumber;
  final String team1Id;
  final String team2Id;
  final int team1Sets;
  final int team2Sets;
  final bool isCompleted;
  final String groupId;
  final bool isFinal;

  const TournamentMatch({
    required this.id,
    required this.roundNumber,
    required this.courtNumber,
    required this.team1Id,
    required this.team2Id,
    this.team1Sets = 0,
    this.team2Sets = 0,
    this.isCompleted = false,
    required this.groupId,
    this.isFinal = false,
  });

  TournamentMatch copyWith({
    String? id,
    int? roundNumber,
    int? courtNumber,
    String? team1Id,
    String? team2Id,
    int? team1Sets,
    int? team2Sets,
    bool? isCompleted,
    String? groupId,
    bool? isFinal,
  }) {
    return TournamentMatch(
      id: id ?? this.id,
      roundNumber: roundNumber ?? this.roundNumber,
      courtNumber: courtNumber ?? this.courtNumber,
      team1Id: team1Id ?? this.team1Id,
      team2Id: team2Id ?? this.team2Id,
      team1Sets: team1Sets ?? this.team1Sets,
      team2Sets: team2Sets ?? this.team2Sets,
      isCompleted: isCompleted ?? this.isCompleted,
      groupId: groupId ?? this.groupId,
      isFinal: isFinal ?? this.isFinal,
    );
  }
}
