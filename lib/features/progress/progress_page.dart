import 'package:flutter/material.dart';

import '../../design_system/app_colors.dart';
import '../../domain/progress.dart';
import '../../domain/routine.dart';
import '../../domain/session.dart';
import '../session/session_page.dart' show formatDuration;

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key, required this.records, required this.now});

  final List<SessionRecord> records;
  final DateTime now;

  String _date(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  String _stepOutcome(StepOutcome outcome) => switch (outcome) {
    StepOutcome.completed => 'fait',
    StepOutcome.partial => 'partiel',
    StepOutcome.skipped => 'passé',
  };

  @override
  Widget build(BuildContext context) {
    final summary = ProgressSummary.fromRecords(records, now);
    final theme = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
          children: [
            Text('Progrès', style: theme.headlineLarge),
            const SizedBox(height: 8),
            Text(summary.message, style: theme.bodyLarge),
            const SizedBox(height: 24),
            Text('Cette semaine', style: theme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Depuis le lundi ${_date(summary.weekStart)}',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _stat(
                      'Séances enregistrées',
                      '${summary.sessionsThisWeek}',
                    ),
                    const Divider(height: 22),
                    _stat('Jours actifs', '${summary.activeDaysThisWeek}'),
                    const Divider(height: 22),
                    _stat(
                      'Temps actif',
                      formatDuration(summary.activeMillisecondsThisWeek),
                    ),
                    const Divider(height: 22),
                    _stat(
                      'Durée totale',
                      formatDuration(summary.totalMillisecondsThisWeek),
                    ),
                    const Divider(height: 22),
                    _stat('Répétitions', '${summary.repetitionsThisWeek}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Un jour actif contient du temps d’exercice ou des répétitions. '
              'Le repos n’enlève rien à vos progrès.',
              style: TextStyle(color: AppColors.muted),
            ),
            if (summary.milestones.isNotEmpty) ...[
              const SizedBox(height: 26),
              Text('Petits jalons', style: theme.headlineSmall),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final label in summary.milestones)
                    Chip(
                      avatar: const Icon(
                        Icons.star_rounded,
                        color: AppColors.accent,
                      ),
                      label: Text(label),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 28),
            Text('Historique', style: theme.headlineSmall),
            const SizedBox(height: 10),
            if (summary.history.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Vos séances apparaîtront ici, même si vous les arrêtez avant la fin.',
                  ),
                ),
              )
            else
              for (final record in summary.history)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ExpansionTile(
                    title: Text(_date(record.endedAt)),
                    subtitle: Text(
                      record.outcome == SessionOutcome.completed
                          ? 'Terminée'
                          : 'Partielle',
                      style: const TextStyle(color: AppColors.accent),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Temps actif : ${formatDuration(record.activeMilliseconds)}',
                      ),
                      Text(
                        'Durée totale : ${formatDuration(record.totalMilliseconds)}',
                      ),
                      Text('Répétitions : ${record.repetitions}'),
                      if (record.feeling != null)
                        Text('Ressenti : ${record.feeling}'),
                      const Divider(height: 24),
                      for (final step in record.steps) ...[
                        Text(
                          '${exerciseById(step.exerciseId).name} · '
                          '${_stepOutcome(step.outcome)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Objectif d’origine : '
                          '${exerciseById(step.exerciseId).targetLabel(step.target)}',
                        ),
                        Text(
                          exerciseById(step.exerciseId).unit ==
                                  ExerciseUnit.repetitions
                              ? 'Réalisé : ${step.repetitions} répétition${step.repetitions > 1 ? 's' : ''}'
                              : 'Réalisé : ${formatDuration(step.activeMilliseconds)}',
                        ),
                        if (step.easierVariant)
                          const Text('Variante plus facile choisie'),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) => Row(
    children: [
      Expanded(child: Text(label)),
      Text(
        value,
        style: const TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    ],
  );
}
