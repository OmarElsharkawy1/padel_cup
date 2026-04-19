import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/tournament/presentation/screens/finals_screen.dart';
import '../../features/tournament/presentation/screens/history_detail_screen.dart';
import '../../features/tournament/presentation/screens/history_list_screen.dart';
import '../../features/tournament/presentation/screens/scoreboard_screen.dart';
import '../../features/tournament/presentation/screens/setup_screen.dart';
import '../../features/tournament/presentation/screens/standings_screen.dart';
import '../../features/tournament/presentation/screens/tournament_shell.dart';
import '../../features/tournament/presentation/providers/tournament_provider.dart';
import 'page_animations.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final hasTournament = ref.read(tournamentProvider) != null;

  return GoRouter(
    initialLocation: hasTournament ? '/scoreboard' : '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => PageAnimations.fadeAnimationPage(
          pageKey: state.pageKey,
          name: state.name,
          screen: const SetupScreen(),
        ),
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
                pageBuilder: (context, state) =>
                    PageAnimations.fadeAnimationPage(
                  pageKey: state.pageKey,
                  name: state.name,
                  screen: const ScoreboardScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/standings',
                pageBuilder: (context, state) =>
                    PageAnimations.fadeAnimationPage(
                  pageKey: state.pageKey,
                  name: state.name,
                  screen: const StandingsScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/finals',
                pageBuilder: (context, state) =>
                    PageAnimations.fadeAnimationPage(
                  pageKey: state.pageKey,
                  name: state.name,
                  screen: const FinalsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/history',
        pageBuilder: (context, state) => PageAnimations.fadeAnimationPage(
          pageKey: state.pageKey,
          name: state.name,
          screen: const HistoryListScreen(),
        ),
      ),
      GoRoute(
        path: '/history/:id',
        pageBuilder: (context, state) => PageAnimations.fadeAnimationPage(
          pageKey: state.pageKey,
          name: state.name,
          screen: HistoryDetailScreen(
            tournamentId: state.pathParameters['id']!,
          ),
        ),
      ),
    ],
  );
});
