import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:padel_cup/l10n/generated/app_localizations.dart';

class TournamentShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const TournamentShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: l10n.setup,
            onPressed: () => context.go('/'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.scoreboard_outlined),
            selectedIcon: const Icon(Icons.scoreboard),
            label: l10n.scoreboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.leaderboard_outlined),
            selectedIcon: const Icon(Icons.leaderboard),
            label: l10n.standings,
          ),
          NavigationDestination(
            icon: const Icon(Icons.emoji_events_outlined),
            selectedIcon: const Icon(Icons.emoji_events),
            label: l10n.finals,
          ),
        ],
      ),
    );
  }
}
