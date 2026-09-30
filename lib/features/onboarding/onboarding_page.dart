import 'package:flutter/material.dart';

import '../../design_system/app_colors.dart';
import '../../domain/routine.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onSaved, this.initialRoutine});

  final Routine? initialRoutine;
  final Future<void> Function(Routine) onSaved;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const dayNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
  late int page;
  late String selection;
  late Set<int> days;
  late Map<String, int> targets;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.initialRoutine;
    page = existing == null ? 0 : 1;
    selection = existing == null
        ? 'plank'
        : existing.steps.length > 1
        ? 'mini'
        : existing.steps.first.exerciseId;
    days = existing == null
        ? {DateTime.monday, DateTime.wednesday, DateTime.friday}
        : {...existing.weekdays};
    targets = {
      for (final exercise in exerciseCatalog)
        exercise.id:
            existing?.steps
                .where((step) => step.exerciseId == exercise.id)
                .firstOrNull
                ?.target ??
            exercise.defaultTarget,
    };
  }

  List<String> get selectedIds =>
      selection == 'mini' ? ['plank', 'squat', 'step_jack'] : [selection];

  Future<void> next() async {
    if (page < 3) {
      setState(() => page++);
      return;
    }
    if (days.isEmpty || saving) return;
    setState(() => saving = true);
    final routine = Routine(
      steps: [
        for (final id in selectedIds)
          RoutineStep(exerciseId: id, target: targets[id]!),
      ],
      weekdays: {...days},
    );
    try {
      await widget.onSaved(routine);
      if (mounted && widget.initialRoutine != null) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enregistrement impossible. Réessayez.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = switch (page) {
      0 => 'On commence petit.',
      1 => 'Votre premier mouvement',
      2 => 'Un objectif à votre mesure',
      _ => 'Quand souhaitez-vous bouger ?',
    };

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.initialRoutine != null,
        title: Text(widget.initialRoutine == null ? 'Bienvenue' : 'Ma routine'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
              children: [
                Text(
                  'ÉTAPE ${page + 1} SUR 4',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Text(title, style: theme.textTheme.headlineLarge),
                const SizedBox(height: 18),
                ...switch (page) {
                  0 => [
                    const Text(
                      'Une séance de quelques secondes suffit pour démarrer. '
                      'Vous pourrez garder, augmenter ou réduire votre objectif quand vous le voudrez.',
                      style: TextStyle(fontSize: 17, height: 1.5),
                    ),
                    const SizedBox(height: 28),
                    const Icon(
                      Icons.wb_sunny_outlined,
                      size: 90,
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Pas de compte à créer. Pas de rattrapage à faire.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Vos choix restent dans ce navigateur. Si vous effacez ses données, ils seront perdus.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ],
                  1 => [
                    const Text('Choisissez un exercice ou une petite routine.'),
                    const SizedBox(height: 18),
                    for (final exercise in exerciseCatalog)
                      _ChoiceCard(
                        title: exercise.name,
                        subtitle: exercise.targetLabel(exercise.defaultTarget),
                        selected: selection == exercise.id,
                        onTap: () => setState(() => selection = exercise.id),
                      ),
                    _ChoiceCard(
                      title: 'Petite routine',
                      subtitle:
                          'Planche + 2 squats + 2 jumping jacks sans saut',
                      selected: selection == 'mini',
                      onTap: () => setState(() => selection = 'mini'),
                    ),
                  ],
                  2 => [
                    const Text(
                      'Ces valeurs sont des exemples. Ajustez-les librement.',
                    ),
                    const SizedBox(height: 18),
                    for (final id in selectedIds)
                      _TargetCard(
                        exercise: exerciseById(id),
                        value: targets[id]!,
                        onChanged: (value) =>
                            setState(() => targets[id] = value),
                      ),
                  ],
                  _ => [
                    const Text(
                      'Le repos compte aussi. Vous pourrez changer ces jours plus tard.',
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var index = 0; index < 7; index++)
                          FilterChip(
                            label: Text(dayNames[index]),
                            selected: days.contains(index + 1),
                            onSelected: (selected) => setState(() {
                              if (selected) {
                                days.add(index + 1);
                              } else {
                                days.remove(index + 1);
                              }
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextButton.icon(
                      onPressed: () => setState(() {
                        days = {1, 2, 3, 4, 5, 6, 7};
                      }),
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: const Text('Tous les jours'),
                    ),
                    if (days.isEmpty)
                      const Text(
                        'Choisissez au moins un jour.',
                        style: TextStyle(color: AppColors.accent),
                      ),
                  ],
                },
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(22, 10, 22, 18),
        child: Row(
          children: [
            if (page > (widget.initialRoutine == null ? 0 : 1))
              IconButton(
                tooltip: 'Étape précédente',
                onPressed: saving ? null : () => setState(() => page--),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            if (page > (widget.initialRoutine == null ? 0 : 1))
              const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: saving || (page == 3 && days.isEmpty) ? null : next,
                child: Text(
                  saving
                      ? 'Enregistrement…'
                      : page == 3
                      ? 'Commencer'
                      : 'Continuer',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppColors.accent : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? AppColors.accent : AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({
    required this.exercise,
    required this.value,
    required this.onChanged,
  });

  final ExerciseSpec exercise;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final increment = exercise.unit == ExerciseUnit.seconds ? 5 : 1;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Réduire ${exercise.name}',
                  onPressed: value <= 1
                      ? null
                      : () => onChanged((value - increment).clamp(1, 300)),
                  icon: const Icon(Icons.remove),
                ),
                Expanded(
                  child: Text(
                    exercise.targetLabel(value),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 17),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Augmenter ${exercise.name}',
                  onPressed: value >= 300
                      ? null
                      : () => onChanged((value + increment).clamp(1, 300)),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
