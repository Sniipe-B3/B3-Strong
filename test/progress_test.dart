import 'package:flutter_test/flutter_test.dart';
import 'package:petit_depart/domain/progress.dart';
import 'package:petit_depart/domain/session.dart';

SessionRecord record({
  required String id,
  required DateTime day,
  int activeMilliseconds = 0,
  int repetitions = 0,
  int totalMilliseconds = 0,
  SessionOutcome outcome = SessionOutcome.completed,
}) => SessionRecord(
  id: id,
  startedAt: day.subtract(const Duration(minutes: 1)),
  endedAt: day,
  outcome: outcome,
  totalMilliseconds: totalMilliseconds,
  steps: [
    StepResult(
      exerciseId: activeMilliseconds > 0 ? 'plank' : 'squat',
      target: activeMilliseconds > 0 ? 10 : 4,
      activeMilliseconds: activeMilliseconds,
      repetitions: repetitions,
      outcome: outcome == SessionOutcome.completed
          ? StepOutcome.completed
          : StepOutcome.partial,
      easierVariant: false,
    ),
  ],
);

void main() {
  test(
    'La semaine du lundi au dimanche additionne les métriques séparément',
    () {
      final records = [
        record(
          id: 'outside',
          day: DateTime(2026, 9, 27, 18),
          activeMilliseconds: 9000,
        ),
        record(
          id: 'monday',
          day: DateTime(2026, 9, 28, 12),
          activeMilliseconds: 5000,
          totalMilliseconds: 12000,
        ),
        record(
          id: 'same-day',
          day: DateTime(2026, 9, 28, 19),
          repetitions: 3,
          totalMilliseconds: 8000,
          outcome: SessionOutcome.partial,
        ),
        record(
          id: 'friday',
          day: DateTime(2026, 10, 2, 9),
          activeMilliseconds: 2000,
          totalMilliseconds: 4000,
        ),
      ];
      final summary = ProgressSummary.fromRecords(
        records,
        DateTime(2026, 10, 2, 20),
      );
      expect(summary.weekStart, DateTime(2026, 9, 28));
      expect(summary.sessionsThisWeek, 3);
      expect(summary.activeDaysThisWeek, 2);
      expect(summary.activeMillisecondsThisWeek, 7000);
      expect(summary.totalMillisecondsThisWeek, 24000);
      expect(summary.repetitionsThisWeek, 3);
      expect(summary.history.first.id, 'friday');
      expect(summary.history.last.id, 'outside');
      expect(summary.milestones, hasLength(2));
    },
  );

  test('Un arrêt sans effort est enregistré sans créer un jour actif', () {
    final summary = ProgressSummary.fromRecords([
      record(
        id: 'zero',
        day: DateTime(2026, 10, 2, 8),
        totalMilliseconds: 3000,
        outcome: SessionOutcome.partial,
      ),
    ], DateTime(2026, 10, 2, 20));
    expect(summary.sessionsThisWeek, 1);
    expect(summary.activeDaysThisWeek, 0);
    expect(summary.totalMillisecondsThisWeek, 3000);
    expect(summary.milestones, isEmpty);
    expect(summary.message, contains('premier pas'));
  });

  test('Une reprise après une semaine ne produit pas de blâme', () {
    final summary = ProgressSummary.fromRecords([
      record(id: 'old', day: DateTime(2026, 9, 24, 18), repetitions: 2),
    ], DateTime(2026, 10, 2, 9));
    expect(summary.sessionsThisWeek, 0);
    expect(summary.message, contains('Heureux de vous retrouver'));
    expect(summary.milestones, ['Premier petit pas']);
  });
}
