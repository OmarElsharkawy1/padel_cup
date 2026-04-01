import 'package:hive/hive.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/tournament_model.dart';

abstract class TournamentLocalDataSource {
  Future<TournamentModel?> getTournament();
  Future<void> saveTournament(TournamentModel model);
  Future<void> deleteTournament();
}

class TournamentLocalDataSourceImpl implements TournamentLocalDataSource {
  static const _key = 'current_tournament';

  @override
  Future<TournamentModel?> getTournament() async {
    final box = Hive.box<TournamentModel>(AppConstants.tournamentBox);
    final response = box.get(_key);
    return response;
  }

  @override
  Future<void> saveTournament(TournamentModel model) async {
    final box = Hive.box<TournamentModel>(AppConstants.tournamentBox);
    final response = await box.put(_key, model);
    return response;
  }

  @override
  Future<void> deleteTournament() async {
    final box = Hive.box<TournamentModel>(AppConstants.tournamentBox);
    final response = await box.delete(_key);
    return response;
  }
}
