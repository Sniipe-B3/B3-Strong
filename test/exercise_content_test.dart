import 'package:flutter_test/flutter_test.dart';
import 'package:petit_depart/domain/exercise_content.dart';
import 'package:petit_depart/domain/routine.dart';
import 'package:petit_depart/domain/session.dart';

void main() {
  test('Chaque exercice de routine possède une fiche sourcée complète', () {
    expect(exerciseCatalog.length, 8);
    expect(exerciseGuides.length, 9);
    expect(
      exerciseCatalog.map((item) => item.id).toSet().length,
      exerciseCatalog.length,
    );
    for (final exercise in exerciseCatalog) {
      final guide = guideById(exercise.id);
      expect(guide.availableInRoutine, isTrue);
      expect(guide.title, exercise.name);
      expect(guide.instructions, isNotEmpty);
      expect(guide.easierVariant, isNotEmpty);
      expect(guide.caution, isNotEmpty);
      expect(guide.illustrationLabel, isNotEmpty);
      expect(Uri.parse(guide.sourceUrl).hasScheme, isTrue);
      expect(guide.sourceName, isNotEmpty);
    }
    expect(
      exerciseGuides.map((item) => item.id).toSet().length,
      exerciseGuides.length,
    );
    expect(
      exerciseGuides.map((item) => item.category).toSet(),
      ExerciseCategory.values.toSet(),
    );
    expect(guideById('calf_stretch').availableInRoutine, isFalse);
  });

  test(
    'Nouveaux exercices, anciennes séances et objectifs restent lisibles',
    () {
      const routine = Routine(
        steps: [
          RoutineStep(exerciseId: 'wall_pushup', target: 2),
          RoutineStep(exerciseId: 'neck_rotation', target: 2),
        ],
        weekdays: {DateTime.friday},
      );
      final restored = Routine.fromJsonString(routine.toJsonString());
      expect(restored.steps.map((step) => step.exerciseId), [
        'wall_pushup',
        'neck_rotation',
      ]);
      expect(restored.hasRepetitions, isTrue);
      final old = SessionRecord(
        id: 'past',
        startedAt: DateTime(2026, 9, 1),
        endedAt: DateTime(2026, 9, 1, 0, 1),
        outcome: SessionOutcome.completed,
        totalMilliseconds: 60000,
        steps: const [
          StepResult(
            exerciseId: 'plank',
            target: 10,
            activeMilliseconds: 10000,
            repetitions: 0,
            outcome: StepOutcome.completed,
            easierVariant: false,
          ),
        ],
      );
      expect(SessionRecord.fromJson(old.toJson()).steps.single.target, 10);
    },
  );
}
