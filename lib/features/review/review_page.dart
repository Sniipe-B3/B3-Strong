import 'package:flutter/material.dart';

import '../../design_system/app_colors.dart';
import '../../domain/review.dart';
import '../../domain/routine.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({
    super.key,
    required this.initialRoutine,
    required this.settings,
    required this.onPeriodChanged,
    required this.onSaved,
  });

  final Routine initialRoutine;
  final ReviewSettings settings;
  final Future<void> Function(int) onPeriodChanged;
  final Future<void> Function(Routine) onSaved;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  late final List<ReviewChoice> choices;
  late int periodDays;
  bool preview = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    choices = List.filled(
      widget.initialRoutine.steps.length,
      ReviewChoice.keep,
    );
    periodDays = widget.settings.periodDays;
  }

  Future<void> changePeriod(int value) async {
    if (saving || value == periodDays) return;
    final previous = periodDays;
    setState(() {
      periodDays = value;
      saving = true;
    });
    try {
      await widget.onPeriodChanged(value);
    } catch (_) {
      if (mounted) {
        setState(() => periodDays = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Période non enregistrée. Réessayez.')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> save() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await widget.onSaved(applyReview(widget.initialRoutine, choices));
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bilan non enregistré. Réessayez.')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  String label(ReviewChoice choice) => switch (choice) {
    ReviewChoice.keep => 'Garder',
    ReviewChoice.increase => 'Augmenter',
    ReviewChoice.reduce => 'Réduire',
    ReviewChoice.postpone => 'Reporter',
  };

  @override
  Widget build(BuildContext context) {
    final routine = widget.initialRoutine;
    final proposed = applyReview(routine, choices);
    return Scaffold(
      appBar: AppBar(title: Text(preview ? 'Vérifier le bilan' : 'Mon bilan')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
              children: preview
                  ? [
                      Text(
                        'À vous de choisir',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Seuls les objectifs de vos prochaines séances changeront. '
                        'Vos séances passées garderont leurs valeurs d’origine.',
                      ),
                      const SizedBox(height: 18),
                      for (var index = 0; index < routine.steps.length; index++)
                        _previewCard(context, index, routine, proposed),
                    ]
                  : [
                      Text(
                        'Un petit point, sans pression',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Vous pouvez garder, augmenter un peu, réduire ou reporter '
                        'chaque exercice. Rien ne change sans votre confirmation.',
                      ),
                      const SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rythme des bilans',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Proposition après une séance et cette période. '
                                'Vous pouvez faire un bilan plus tôt si vous voulez.',
                              ),
                              const SizedBox(height: 12),
                              DropdownButton<int>(
                                value: periodDays,
                                isExpanded: true,
                                onChanged: saving
                                    ? null
                                    : (value) {
                                        if (value != null) changePeriod(value);
                                      },
                                items: [
                                  for (final days in reviewPeriods)
                                    DropdownMenuItem(
                                      value: days,
                                      child: Text('Tous les $days jours'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (var index = 0; index < routine.steps.length; index++)
                        _choiceCard(context, index, routine.steps[index]),
                    ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(22, 8, 22, 18),
        child: preview
            ? Row(
                children: [
                  TextButton(
                    onPressed: saving
                        ? null
                        : () => setState(() => preview = false),
                    child: const Text('Modifier'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: saving ? null : save,
                      child: Text(
                        saving ? 'Enregistrement…' : 'Confirmer mon bilan',
                      ),
                    ),
                  ),
                ],
              )
            : FilledButton(
                onPressed: saving ? null : () => setState(() => preview = true),
                child: const Text('Voir mon choix'),
              ),
      ),
    );
  }

  Widget _choiceCard(BuildContext context, int index, RoutineStep step) {
    final exercise = exerciseById(step.exerciseId);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exercise.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Objectif actuel : ${exercise.targetLabel(step.target)}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final choice in ReviewChoice.values)
                  ChoiceChip(
                    label: Text(label(choice)),
                    tooltip: '${label(choice)} ${exercise.name}',
                    selected: choices[index] == choice,
                    onSelected:
                        reviewedTarget(step, choice) == step.target &&
                            (choice == ReviewChoice.increase ||
                                choice == ReviewChoice.reduce)
                        ? null
                        : (_) => setState(() => choices[index] = choice),
                  ),
              ],
            ),
            if (choices[index] == ReviewChoice.postpone) ...[
              const SizedBox(height: 8),
              const Text(
                'Aucun changement maintenant. Nous le reproposerons au prochain bilan.',
                style: TextStyle(color: AppColors.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _previewCard(
    BuildContext context,
    int index,
    Routine before,
    Routine after,
  ) {
    final step = before.steps[index];
    final exercise = exerciseById(step.exerciseId);
    final next = after.steps[index];
    final choice = choices[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exercise.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              '${exercise.targetLabel(step.target)} → ${exercise.targetLabel(next.target)}',
            ),
            const SizedBox(height: 4),
            Text(
              choice == ReviewChoice.postpone
                  ? 'Reporté au prochain bilan'
                  : label(choice),
              style: const TextStyle(color: AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}
