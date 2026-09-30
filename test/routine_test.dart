import 'package:flutter_test/flutter_test.dart';
import 'package:petit_depart/domain/routine.dart';

void main() {
  test(
    'La routine garde exercices, objectifs et jours après sérialisation',
    () {
      const routine = Routine(
        steps: [
          RoutineStep(exerciseId: 'plank', target: 15),
          RoutineStep(exerciseId: 'squat', target: 3),
        ],
        weekdays: {DateTime.monday, DateTime.friday},
      );
      final restored = Routine.fromJsonString(routine.toJsonString());

      expect(restored.steps.map((step) => step.exerciseId), ['plank', 'squat']);
      expect(restored.steps.map((step) => step.target), [15, 3]);
      expect(restored.weekdays, {DateTime.monday, DateTime.friday});
      expect(restored.isScheduledOn(DateTime(2026, 9, 28)), isTrue);
      expect(restored.isScheduledOn(DateTime(2026, 9, 29)), isFalse);
    },
  );

  test('Une routine vide ou un objectif invalide sont refusés', () {
    expect(
      () => Routine.fromJsonString('{"version":1,"steps":[],"weekdays":[1]}'),
      throwsFormatException,
    );
    expect(
      () => Routine.fromJsonString(
        '{"version":1,"steps":[{"exerciseId":"plank","target":0}],"weekdays":[1]}',
      ),
      throwsFormatException,
    );
  });
}
