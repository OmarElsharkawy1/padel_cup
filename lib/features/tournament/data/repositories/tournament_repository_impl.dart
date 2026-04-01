import '../../domain/entities/tournament.dart';
import '../../domain/repositories/tournament_repository.dart';
import '../datasources/tournament_local_datasource.dart';
import '../models/tournament_model.dart';

class TournamentRepositoryImpl implements TournamentRepository {
  final TournamentLocalDataSource _localDataSource;

  const TournamentRepositoryImpl(this._localDataSource);

  @override
  Future<Tournament?> getTournament() async {
    final response = await _localDataSource.getTournament();
    return response?.toEntity();
  }

  @override
  Future<void> saveTournament(Tournament tournament) async {
    final model = TournamentModel.fromEntity(tournament);
    final response = await _localDataSource.saveTournament(model);
    return response;
  }

  @override
  Future<void> deleteTournament() async {
    final response = await _localDataSource.deleteTournament();
    return response;
  }
}
