import 'package:flutter/material.dart';

import '../../design_system/app_colors.dart';
import '../../domain/routine.dart';

class RoutineEditorPage extends StatefulWidget {
  const RoutineEditorPage({
    super.key,
    required this.initialRoutine,
    required this.onSaved,
  });

  final Routine initialRoutine;
  final Future<void> Function(Routine) onSaved;

  @override
  State<RoutineEditorPage> createState() => _RoutineEditorPageState();
}

class _RoutineEditorPageState extends State<RoutineEditorPage> {
  static const dayNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
  late List<RoutineStep> steps;
  late Set<int> days;
  bool preview = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    steps = List.of(widget.initialRoutine.steps);
    days = {...widget.initialRoutine.weekdays};
  }

  Routine get proposed => Routine(steps: List.of(steps), weekdays: {...days});
  bool get changed =>
      proposed.toJsonString() != widget.initialRoutine.toJsonString();

  void replaceStep(int index, RoutineStep step) =>
      setState(() => steps[index] = step);

  void moveStep(int from, int to) => setState(() {
    final step = steps.removeAt(from);
    steps.insert(to, step);
  });

  Future<void> save() async {
    if (saving || steps.isEmpty || days.isEmpty) return;
    setState(() => saving = true);
    try {
      await widget.onSaved(proposed);
      if (mounted) Navigator.of(context).pop();
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

  String stepLabel(RoutineStep step) {
    final exercise = exerciseById(step.exerciseId);
    final target = exercise.targetLabel(step.target);
    if (step.sets == 1) return '${exercise.name} · $target';
    return '${exercise.name} · ${step.sets} séries de $target · ${step.restSeconds} s de repos';
  }

  String dayLabels(Set<int> weekdays) {
    final sorted = weekdays.toList()..sort();
    return sorted.map((day) => dayNames[day - 1]).join(', ');
  }

  Widget counter({
    required String label,
    required String tooltip,
    required String value,
    required int current,
    required int minimum,
    required int maximum,
    required int increment,
    required ValueChanged<int> onChanged,
  }) => Row(
    children: [
      Expanded(child: Text(label)),
      IconButton.filledTonal(
        tooltip: 'Réduire $tooltip',
        onPressed: current <= minimum
            ? null
            : () => onChanged((current - increment).clamp(minimum, maximum)),
        icon: const Icon(Icons.remove),
      ),
      SizedBox(width: 76, child: Text(value, textAlign: TextAlign.center)),
      IconButton.filledTonal(
        tooltip: 'Augmenter $tooltip',
        onPressed: current >= maximum
            ? null
            : () => onChanged((current + increment).clamp(minimum, maximum)),
        icon: const Icon(Icons.add),
      ),
    ],
  );

  Widget editStep(int index) {
    final step = steps[index];
    final exercise = exerciseById(step.exerciseId);
    final targetIncrement = exercise.unit == ExerciseUnit.seconds ? 5 : 1;
    return Card(
      key: ValueKey(step.exerciseId),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    exercise.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Monter ${exercise.name}',
                  onPressed: index == 0
                      ? null
                      : () => moveStep(index, index - 1),
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
                IconButton(
                  tooltip: 'Descendre ${exercise.name}',
                  onPressed: index == steps.length - 1
                      ? null
                      : () => moveStep(index, index + 1),
                  icon: const Icon(Icons.arrow_downward_rounded),
                ),
                IconButton(
                  tooltip: 'Retirer ${exercise.name}',
                  onPressed: steps.length == 1
                      ? null
                      : () => setState(() => steps.removeAt(index)),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
            counter(
              label: 'Objectif',
              tooltip: 'objectif ${exercise.name}',
              value: exercise.targetLabel(step.target),
              current: step.target,
              minimum: 1,
              maximum: 300,
              increment: targetIncrement,
              onChanged: (value) => replaceStep(
                index,
                RoutineStep(
                  exerciseId: step.exerciseId,
                  target: value,
                  sets: step.sets,
                  restSeconds: step.restSeconds,
                ),
              ),
            ),
            const SizedBox(height: 8),
            counter(
              label: 'Séries',
              tooltip: 'séries ${exercise.name}',
              value: '${step.sets}',
              current: step.sets,
              minimum: 1,
              maximum: 5,
              increment: 1,
              onChanged: (value) => replaceStep(
                index,
                RoutineStep(
                  exerciseId: step.exerciseId,
                  target: step.target,
                  sets: value,
                  restSeconds: value == 1 ? 0 : step.restSeconds,
                ),
              ),
            ),
            if (step.sets > 1) ...[
              const SizedBox(height: 8),
              counter(
                label: 'Repos entre séries',
                tooltip: 'repos ${exercise.name}',
                value: '${step.restSeconds} s',
                current: step.restSeconds,
                minimum: 0,
                maximum: 120,
                increment: 15,
                onChanged: (value) => replaceStep(
                  index,
                  RoutineStep(
                    exerciseId: step.exerciseId,
                    target: step.target,
                    sets: step.sets,
                    restSeconds: value,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget routineSummary(String title, Routine routine) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          for (var index = 0; index < routine.steps.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Text('${index + 1}. ${stepLabel(routine.steps[index])}'),
            ),
          const SizedBox(height: 5),
          Text('Jours : ${dayLabels(routine.weekdays)}'),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final available = exerciseCatalog
        .where(
          (exercise) => !steps.any((step) => step.exerciseId == exercise.id),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(preview ? 'Vérifier la routine' : 'Adapter ma routine'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
              children: preview
                  ? [
                      Text(
                        'Avant d’enregistrer',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Les séances déjà enregistrées garderont leurs anciens objectifs.',
                      ),
                      const SizedBox(height: 22),
                      routineSummary('Routine actuelle', widget.initialRoutine),
                      routineSummary('Prochaine routine', proposed),
                    ]
                  : [
                      Text(
                        'Votre prochaine séance',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ajoutez, retirez et réordonnez vos exercices à votre rythme.',
                      ),
                      const SizedBox(height: 22),
                      for (var index = 0; index < steps.length; index++)
                        editStep(index),
                      if (available.isNotEmpty)
                        PopupMenuButton<ExerciseSpec>(
                          tooltip: 'Ajouter un exercice',
                          onSelected: (exercise) => setState(
                            () => steps.add(
                              RoutineStep(
                                exerciseId: exercise.id,
                                target: exercise.defaultTarget,
                              ),
                            ),
                          ),
                          itemBuilder: (_) => [
                            for (final exercise in available)
                              PopupMenuItem(
                                value: exercise,
                                child: Text(exercise.name),
                              ),
                          ],
                          child: const ListTile(
                            leading: Icon(
                              Icons.add_circle_outline,
                              color: AppColors.accent,
                            ),
                            title: Text('Ajouter un exercice'),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Text(
                        'Jours souhaités',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
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
                      if (days.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Text(
                            'Choisissez au moins un jour.',
                            style: TextStyle(color: AppColors.accent),
                          ),
                        ),
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
                        saving ? 'Enregistrement…' : 'Enregistrer la routine',
                      ),
                    ),
                  ),
                ],
              )
            : FilledButton(
                onPressed: !changed || days.isEmpty
                    ? null
                    : () => setState(() => preview = true),
                child: const Text('Voir les changements'),
              ),
      ),
    );
  }
}
