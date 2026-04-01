import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/constants/app_constants.dart';
import 'features/tournament/data/models/match_model.dart';
import 'features/tournament/data/models/team_model.dart';
import 'features/tournament/data/models/tournament_model.dart';

Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(TeamModelAdapter());
  Hive.registerAdapter(MatchModelAdapter());
  Hive.registerAdapter(TournamentModelAdapter());

  // Open boxes
  await Hive.openBox<TournamentModel>(AppConstants.tournamentBox);
  await Hive.openBox(AppConstants.settingsBox);

  runApp(
    ProviderScope(
      child: PadelCupApp(config: config),
    ),
  );
}
