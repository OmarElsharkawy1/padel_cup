import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/constants/app_constants.dart';
import 'features/tournament/presentation/providers/tournament_provider.dart';
import 'features/tournament/data/models/match_model.dart';
import 'features/tournament/data/models/team_model.dart';
import 'features/tournament/data/models/tournament_model.dart';

Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Register adapters
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(TeamModelAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(MatchModelAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(TournamentModelAdapter());
  }

  // Open boxes
  await Hive.openBox<TournamentModel>(AppConstants.tournamentBox);
  await Hive.openBox<TournamentModel>(AppConstants.historyBox);
  await Hive.openBox(AppConstants.settingsBox);

  // Pre-load tournament to determine initial route synchronously
  final box = Hive.box<TournamentModel>(AppConstants.tournamentBox);
  final savedTournament = box.get('current_tournament');

  runApp(
    ProviderScope(
      overrides: [
        initialTournamentProvider.overrideWithValue(savedTournament?.toEntity()),
      ],
      child: PadelCupApp(config: config),
    ),
  );
}
