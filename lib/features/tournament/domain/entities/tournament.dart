import 'match.dart';
import 'team.dart';

enum TournamentStatus { setup, groupStage, finals, completed }

class Tournament {
  final String id;
  final String name;
  final List<Team> teams;
  final List<TournamentMatch> matches;
  final int matchTimerMinutes;
  final TournamentStatus status;
  final DateTime createdAt;

  Tournament({
    required this.id,
    required this.name,
    required this.teams,
    required this.matches,
    this.matchTimerMinutes = 0,
    this.status = TournamentStatus.setup,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  List<Team> get groupATeams =>
      teams.where((t) => t.groupId == 'A').toList();

  List<Team> get groupBTeams =>
      teams.where((t) => t.groupId == 'B').toList();

  List<TournamentMatch> get groupMatches =>
      matches.where((m) => !m.isFinal).toList();

  List<TournamentMatch> get finalMatches =>
      matches.where((m) => m.isFinal).toList();

  bool get allGroupMatchesCompleted =>
      groupMatches.every((m) => m.isCompleted);

  Tournament copyWith({
    String? id,
    String? name,
    List<Team>? teams,
    List<TournamentMatch>? matches,
    int? matchTimerMinutes,
    TournamentStatus? status,
    DateTime? createdAt,
  }) {
    return Tournament(
      id: id ?? this.id,
      name: name ?? this.name,
      teams: teams ?? this.teams,
      matches: matches ?? this.matches,
      matchTimerMinutes: matchTimerMinutes ?? this.matchTimerMinutes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
