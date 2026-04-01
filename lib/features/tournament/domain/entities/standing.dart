class Standing implements Comparable<Standing> {
  final String teamId;
  final String teamName;
  final int played;
  final int wins;
  final int ties;
  final int losses;
  final int points;
  final int setsWon;
  final int setsLost;

  const Standing({
    required this.teamId,
    required this.teamName,
    this.played = 0,
    this.wins = 0,
    this.ties = 0,
    this.losses = 0,
    this.points = 0,
    this.setsWon = 0,
    this.setsLost = 0,
  });

  int get setDifference => setsWon - setsLost;

  @override
  int compareTo(Standing other) {
    final pointsDiff = other.points.compareTo(points);
    if (pointsDiff != 0) return pointsDiff;
    return other.setDifference.compareTo(setDifference);
  }
}
