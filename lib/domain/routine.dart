import 'dart:convert';

enum ExerciseUnit { seconds, repetitions }

class ExerciseSpec {
  const ExerciseSpec(this.id, this.name, this.unit, this.defaultTarget);

  final String id;
  final String name;
  final ExerciseUnit unit;
  final int defaultTarget;

  String targetLabel(int value) => switch (unit) {
    ExerciseUnit.seconds => '$value seconde${value > 1 ? 's' : ''}',
    ExerciseUnit.repetitions => '$value répétition${value > 1 ? 's' : ''}',
  };
}

const exerciseCatalog = <ExerciseSpec>[
  ExerciseSpec('plank', 'Planche', ExerciseUnit.seconds, 10),
  ExerciseSpec('squat', 'Squats', ExerciseUnit.repetitions, 2),
  ExerciseSpec(
    'step_jack',
    'Jumping jack sans saut',
    ExerciseUnit.repetitions,
    2,
  ),
];

ExerciseSpec exerciseById(String id) => exerciseCatalog.firstWhere(
  (exercise) => exercise.id == id,
  orElse: () => throw FormatException('Exercice inconnu : $id'),
);

class RoutineStep {
  const RoutineStep({
    required this.exerciseId,
    required this.target,
    this.sets = 1,
    this.restSeconds = 0,
  });

  final String exerciseId;
  final int target;
  final int sets;
  final int restSeconds;

  Map<String, Object> toJson() => {
    'exerciseId': exerciseId,
    'target': target,
    'sets': sets,
    'restSeconds': restSeconds,
  };

  factory RoutineStep.fromJson(Map<String, dynamic> json) {
    final id = json['exerciseId'];
    final target = json['target'];
    // Existing routines have no series/rest fields: one set, no rest.
    final sets = json['sets'] ?? 1;
    final restSeconds = json['restSeconds'] ?? 0;
    if (id is! String ||
        target is! int ||
        target < 1 ||
        target > 300 ||
        sets is! int ||
        sets < 1 ||
        sets > 5 ||
        restSeconds is! int ||
        restSeconds < 0 ||
        restSeconds > 120) {
      throw const FormatException('Étape de routine invalide');
    }
    exerciseById(id);
    return RoutineStep(
      exerciseId: id,
      target: target,
      sets: sets,
      restSeconds: sets == 1 ? 0 : restSeconds,
    );
  }
}

class Routine {
  const Routine({required this.steps, required this.weekdays});

  final List<RoutineStep> steps;
  final Set<int> weekdays;

  bool isScheduledOn(DateTime day) => weekdays.contains(day.weekday);

  bool get hasRepetitions => steps.any(
    (step) => exerciseById(step.exerciseId).unit == ExerciseUnit.repetitions,
  );

  int get estimatedTimedSeconds => steps.fold<int>(0, (total, step) {
    final unit = exerciseById(step.exerciseId).unit;
    return total +
        (unit == ExerciseUnit.seconds
            ? (step.target + 3) * step.sets + step.restSeconds * (step.sets - 1)
            : 0);
  });

  String toJsonString() => jsonEncode({
    'version': 1,
    'steps': steps.map((step) => step.toJson()).toList(),
    'weekdays': weekdays.toList()..sort(),
  });

  factory Routine.fromJsonString(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic> || decoded['version'] != 1) {
      throw const FormatException('Version de routine inconnue');
    }
    final rawSteps = decoded['steps'];
    final rawWeekdays = decoded['weekdays'];
    if (rawSteps is! List || rawWeekdays is! List) {
      throw const FormatException('Routine invalide');
    }
    final steps = rawSteps.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Exercice invalide');
      }
      return RoutineStep.fromJson(item);
    }).toList();
    final weekdays = rawWeekdays.map((day) {
      if (day is! int || day < DateTime.monday || day > DateTime.sunday) {
        throw const FormatException('Jour invalide');
      }
      return day;
    }).toSet();
    if (steps.isEmpty || weekdays.isEmpty) {
      throw const FormatException('Routine vide');
    }
    return Routine(steps: steps, weekdays: weekdays);
  }
}
