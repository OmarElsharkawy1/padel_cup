import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:padel_cup/l10n/generated/app_localizations.dart';

import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/tournament_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final history = ref.watch(tournamentHistoryProvider);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                l10n.appTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            const Divider(),

            // ── Theme ──
            _buildToggleRow(
              context,
              icon: Icons.palette,
              title: l10n.theme,
              isFirstSelected: themeMode == ThemeMode.light,
              firstIcon: Icons.light_mode,
              secondIcon: Icons.dark_mode,
              onChanged: (isLight) {
                ref.read(themeModeProvider.notifier).setThemeMode(
                      isLight ? ThemeMode.light : ThemeMode.dark,
                    );
              },
            ),
            const SizedBox(height: 8),

            // ── Language ──
            _buildToggleRow(
              context,
              icon: Icons.language,
              title: l10n.language,
              isFirstSelected: locale.languageCode == 'en',
              firstIcon: null,
              firstLabel: 'EN',
              secondIcon: null,
              secondLabel: 'AR',
              onChanged: (isEnglish) {
                ref.read(localeProvider.notifier).setLocale(
                      isEnglish ? const Locale('en') : const Locale('ar'),
                    );
              },
            ),
            const Divider(height: 24),

            // ── Tournament History ──
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(l10n.tournamentHistory),
              trailing: history.isNotEmpty
                  ? Badge.count(
                      count: history.length,
                      child: const Icon(Icons.chevron_right),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                context.push('/history');
              },
            ),

            const Spacer(),

            // ── Reset Tournament ──
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () => _showResetDialog(context, ref),
                icon: const Icon(Icons.restart_alt),
                label: Text(l10n.resetTournament),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isFirstSelected,
    required ValueChanged<bool> onChanged,
    IconData? firstIcon,
    IconData? secondIcon,
    String? firstLabel,
    String? secondLabel,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _toggleOption(
                  context,
                  isSelected: isFirstSelected,
                  icon: firstIcon,
                  text: firstLabel,
                  onTap: () => onChanged(true),
                ),
                _toggleOption(
                  context,
                  isSelected: !isFirstSelected,
                  icon: secondIcon,
                  text: secondLabel,
                  onTap: () => onChanged(false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleOption(
    BuildContext context, {
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
    String? text,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: icon != null
            ? Icon(
                icon,
                size: 20,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              )
            : Text(
                text ?? '',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.resetTournament),
        content: Text(l10n.resetConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx); // close dialog
              Navigator.pop(context); // close drawer
              ref.read(tournamentProvider.notifier).resetTournament();
              ref.read(tournamentHistoryProvider.notifier).refresh();
              context.go('/');
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.reset),
          ),
        ],
      ),
    );
  }
}
