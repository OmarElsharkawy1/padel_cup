import 'package:flutter/material.dart';
import 'package:padel_cup/l10n/generated/app_localizations.dart';

class MatchScoreDialog extends StatefulWidget {
  final String team1Name;
  final String team2Name;

  const MatchScoreDialog({
    super.key,
    required this.team1Name,
    required this.team2Name,
  });

  @override
  State<MatchScoreDialog> createState() => _MatchScoreDialogState();
}

class _MatchScoreDialogState extends State<MatchScoreDialog> {
  int _team1Sets = 0;
  int _team2Sets = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.enterScore),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ScoreRow(
            teamName: widget.team1Name,
            score: _team1Sets,
            onIncrement: () => setState(() => _team1Sets++),
            onDecrement: () {
              if (_team1Sets > 0) setState(() => _team1Sets--);
            },
          ),
          const SizedBox(height: 16),
          _ScoreRow(
            teamName: widget.team2Name,
            score: _team2Sets,
            onIncrement: () => setState(() => _team2Sets++),
            onDecrement: () {
              if (_team2Sets > 0) setState(() => _team2Sets--);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            (team1Sets: _team1Sets, team2Sets: _team2Sets),
          ),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String teamName;
  final int score;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _ScoreRow({
    required this.teamName,
    required this.score,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            teamName,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        IconButton.outlined(
          onPressed: onDecrement,
          icon: const Icon(Icons.remove),
          iconSize: 20,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '$score',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        IconButton.filled(
          onPressed: onIncrement,
          icon: const Icon(Icons.add),
          iconSize: 20,
        ),
      ],
    );
  }
}
