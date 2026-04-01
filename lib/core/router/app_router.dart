import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/tournament/presentation/screens/finals_screen.dart';
import '../../features/tournament/presentation/screens/scoreboard_screen.dart';
import '../../features/tournament/presentation/screens/setup_screen.dart';
import '../../features/tournament/presentation/screens/standings_screen.dart';
import '../../features/tournament/presentation/screens/tournament_shell.dart';
import '../../features/tournament/presentation/providers/tournament_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Determine initial location based on existing tournament
  final tournamentAsync = ref.read(tournamentProvider);
  final hasTournament = tournamentAsync.value != null;

  return GoRouter(
    initialLocation: hasTournament ? '/scoreboard' : '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SetupScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return TournamentShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/scoreboard',
                builder: (context, state) => const ScoreboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/standings',
                builder: (context, state) => const StandingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/finals',
                builder: (context, state) => const FinalsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
