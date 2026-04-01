import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:padel_cup/l10n/generated/app_localizations.dart';

import '../../../../core/constants/app_constants.dart';
import '../providers/tournament_provider.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _timerController = TextEditingController(text: '10');
  final _groupAControllers =
      List.generate(AppConstants.teamsPerGroup, (_) => TextEditingController());
  final _groupBControllers =
      List.generate(AppConstants.teamsPerGroup, (_) => TextEditingController());

  @override
  void dispose() {
    _nameController.dispose();
    _timerController.dispose();
    for (final c in _groupAControllers) {
      c.dispose();
    }
    for (final c in _groupBControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _startTournament() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(tournamentProvider.notifier).createTournament(
          name: _nameController.text.trim(),
          groupANames: _groupAControllers.map((c) => c.text.trim()).toList(),
          groupBNames: _groupBControllers.map((c) => c.text.trim()).toList(),
          matchTimerMinutes: int.tryParse(_timerController.text) ?? 0,
        );

    if (mounted) {
      context.go('/scoreboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWide = MediaQuery.sizeOf(context).width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.setup),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.tournamentName,
                prefixIcon: const Icon(Icons.emoji_events),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.enterTournamentName : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _timerController,
              decoration: InputDecoration(
                labelText: l10n.matchTimer,
                prefixIcon: const Icon(Icons.timer),
                helperText: l10n.firstToSets(AppConstants.setsToWin),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildGroupSection(l10n.groupA, _groupAControllers, l10n)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildGroupSection(l10n.groupB, _groupBControllers, l10n)),
                ],
              )
            else ...[
              _buildGroupSection(l10n.groupA, _groupAControllers, l10n),
              const SizedBox(height: 16),
              _buildGroupSection(l10n.groupB, _groupBControllers, l10n),
            ],
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _startTournament,
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.startTournament),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupSection(
    String title,
    List<TextEditingController> controllers,
    AppLocalizations l10n,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < controllers.length; i++) ...[
              TextFormField(
                controller: controllers[i],
                decoration: InputDecoration(
                  labelText: l10n.teamNumber(i + 1),
                  prefixIcon: const Icon(Icons.group),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.enterTeamNames : null,
              ),
              if (i < controllers.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
