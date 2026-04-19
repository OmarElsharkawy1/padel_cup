import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:padel_cup/l10n/generated/app_localizations.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/usecases/parse_schedule_image.dart';
import '../providers/tournament_provider.dart';
import '../widgets/app_drawer.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _timerController = TextEditingController(text: '20');
  final _groupAControllers =
      List.generate(AppConstants.teamsPerGroup, (_) => TextEditingController());
  final _groupBControllers =
      List.generate(AppConstants.teamsPerGroup, (_) => TextEditingController());

  bool _didPrefill = false;
  bool _isImporting = false;

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

  void _prefillFromTournament() {
    if (_didPrefill) return;
    _didPrefill = true;

    final tournament = ref.read(tournamentProvider);
    if (tournament == null) return;

    _nameController.text = tournament.name;
    _timerController.text = tournament.matchTimerMinutes.toString();

    final groupATeams = tournament.groupATeams;
    for (var i = 0; i < groupATeams.length && i < _groupAControllers.length; i++) {
      _groupAControllers[i].text = groupATeams[i].name;
    }

    final groupBTeams = tournament.groupBTeams;
    for (var i = 0; i < groupBTeams.length && i < _groupBControllers.length; i++) {
      _groupBControllers[i].text = groupBTeams[i].name;
    }
  }

  Future<void> _importFromImage() async {
    final l10n = AppLocalizations.of(context)!;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null || !mounted) return;

    setState(() => _isImporting = true);

    try {
      const parser = ParseScheduleImage();
      final result = await parser(File(pickedFile.path));

      if (!mounted) return;

      if (!result.hasTeams) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.importFailed),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      // If we got full match schedule with exactly 5 teams per group,
      // create tournament directly
      if (result.hasMatches &&
          result.groupATeams.length == 5 &&
          result.groupBTeams.length == 5) {
        final tournamentName = _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : 'Padel Cup';
        final timer = int.tryParse(_timerController.text) ?? 20;

        await ref.read(tournamentProvider.notifier).createTournamentFromImage(
              name: tournamentName,
              schedule: result,
              matchTimerMinutes: timer,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.importSuccess),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/scoreboard');
        }
        return;
      }

      // Fallback: just fill team names for manual setup
      for (var i = 0;
          i < result.groupATeams.length && i < _groupAControllers.length;
          i++) {
        _groupAControllers[i].text = result.groupATeams[i];
      }
      for (var i = 0;
          i < result.groupBTeams.length && i < _groupBControllers.length;
          i++) {
        _groupBControllers[i].text = result.groupBTeams[i];
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.importSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.importFailed),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
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
    _prefillFromTournament();

    final l10n = AppLocalizations.of(context)!;
    final isWide = MediaQuery.sizeOf(context).width > 600;
    final hasTournament = ref.read(tournamentProvider) != null;

    return Scaffold(
      appBar: AppBar(
        leading: hasTournament
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/scoreboard'),
              )
            : null,
        title: Text(l10n.setup),
      ),
      drawer: hasTournament ? null : const AppDrawer(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Import from Image ──
            OutlinedButton.icon(
              onPressed: _isImporting ? null : _importFromImage,
              icon: _isImporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.image),
              label: Text(
                _isImporting ? l10n.importing : l10n.importFromImage,
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 16),

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
