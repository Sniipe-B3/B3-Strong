import 'package:flutter_test/flutter_test.dart';
import 'package:petit_depart/domain/review.dart';
import 'package:petit_depart/domain/routine.dart';
import 'package:petit_depart/domain/session.dart';

SessionRecord record(String id, DateTime endedAt) => SessionRecord(
  id: id,
  startedAt: endedAt.subtract(const Duration(minutes: 1)),
  endedAt: endedAt,
  outcome: SessionOutcome.completed,
  totalMilliseconds: 60000,
  steps: const [],
);

void main() {
  test('Bilan proposé après la période choisie, jamais sans séance', () {
    final first = DateTime(2026, 9, 25, 10);
    final records = [record('first', first)];
    final week = ReviewSchedule.fromRecords(records, const ReviewSettings());
    expect(week.isDue(DateTime(2026, 10, 1)), isFalse);
    expect(week.isDue(DateTime(2026, 10, 2)), isTrue);
    final fortnight = ReviewSchedule.fromRecords(
      records,
      const ReviewSettings(periodDays: 14),
    );
    expect(fortnight.isDue(DateTime(2026, 10, 2)), isFalse);
    expect(
      ReviewSchedule.fromRecords([], const ReviewSettings()).dueAt,
      isNull,
    );
  });

  test('Après bilan, seule une nouvelle séance relance la période', () {
    final old = record('old', DateTime(2026, 9, 1));
    final settings = ReviewSettings(lastReviewedAt: DateTime(2026, 9, 8));
    expect(ReviewSchedule.fromRecords([old], settings).dueAt, isNull);
    final newRecord = record('new', DateTime(2026, 9, 10));
    final schedule = ReviewSchedule.fromRecords([old, newRecord], settings);
    expect(schedule.dueAt, DateTime(2026, 9, 17));
  });

  test('Choix par exercice et bornes sans modifier la routine originale', () {
    const routine = Routine(
      steps: [
        RoutineStep(exerciseId: 'plank', target: 10, sets: 2, restSeconds: 15),
        RoutineStep(exerciseId: 'squat', target: 2),
        RoutineStep(exerciseId: 'step_jack', target: 3),
      ],
      weekdays: {DateTime.monday},
    );
    final next = applyReview(routine, [
      ReviewChoice.increase,
      ReviewChoice.reduce,
      ReviewChoice.postpone,
    ]);
    expect(next.steps.map((step) => step.target), [15, 1, 3]);
    expect(routine.steps.map((step) => step.target), [10, 2, 3]);
    expect(next.steps.first.sets, 2);
    expect(next.steps.first.restSeconds, 15);
    expect(next.weekdays, {DateTime.monday});
    expect(
      applyReview(routine, List.filled(3, ReviewChoice.keep)).toJsonString(),
      routine.toJsonString(),
    );
    expect(
      reviewedTarget(
        const RoutineStep(exerciseId: 'plank', target: 1),
        ReviewChoice.reduce,
      ),
      1,
    );
    expect(
      reviewedTarget(
        const RoutineStep(exerciseId: 'squat', target: 300),
        ReviewChoice.increase,
      ),
      300,
    );
  });

  test('Préférences de bilan persistantes et invalides rejetées', () {
    final settings = ReviewSettings(
      periodDays: 28,
      lastReviewedAt: DateTime(2026, 10, 2, 9),
    );
    final restored = ReviewSettings.fromJsonString(settings.toJsonString());
    expect(restored.periodDays, 28);
    expect(restored.lastReviewedAt, settings.lastReviewedAt);
    expect(
      () => ReviewSettings.fromJsonString(
        '{"version":1,"periodDays":0,"lastReviewedAt":null}',
      ),
      throwsFormatException,
    );
  });
}
