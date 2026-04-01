import '../entities/tournament.dart';

abstract class TournamentRepository {
  Future<Tournament?> getTournament();
  Future<void> saveTournament(Tournament tournament);
  Future<void> deleteTournament();
}
