import '../entities/tournament.dart';
import '../repositories/tournament_repository.dart';

class UpdateMatchResult {
  final TournamentRepository _repository;

  const UpdateMatchResult(this._repository);

  Future<Tournament> call({
    required Tournament tournament,
    required String matchId,
    required int team1Sets,
    required int team2Sets,
  }) async {
    final updatedMatches = tournament.matches.map((m) {
      if (m.id == matchId) {
        return m.copyWith(
          team1Sets: team1Sets,
          team2Sets: team2Sets,
          isCompleted: true,
        );
      }
      return m;
    }).toList();

    var status = tournament.status;
    final groupMatches = updatedMatches.where((m) => !m.isFinal);
    if (status == TournamentStatus.groupStage &&
        groupMatches.every((m) => m.isCompleted)) {
      status = TournamentStatus.finals;
    }

    // Check if finals are completed
    final finalMatches = updatedMatches.where((m) => m.isFinal);
    if (status == TournamentStatus.finals &&
        finalMatches.isNotEmpty &&
        finalMatches.every((m) => m.isCompleted)) {
      status = TournamentStatus.completed;
    }

    final updated = tournament.copyWith(
      matches: updatedMatches,
      status: status,
    );

    await _repository.saveTournament(updated);
    return updated;
  }
}
