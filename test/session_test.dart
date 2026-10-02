import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:petit_depart/domain/routine.dart';
import 'package:petit_depart/domain/session.dart';

void main() {
  final started = DateTime(2026, 9, 30, 10);

  test('Préparation et pause ne gonflent pas le temps actif', () {
    final session = SessionDraft.start(
      const Routine(
        steps: [RoutineStep(exerciseId: 'plank', target: 10)],
        weekdays: {DateTime.wednesday},
      ),
      started,
    );
    session.advance(3000);
    expect(session.phase, SessionPhase.timed);
    expect(session.currentActiveMilliseconds, 0);
    session.advance(2000);
    session.togglePause();
    session.advance(5000);
    expect(session.currentActiveMilliseconds, 2000);
    session.togglePause();
    session.advance(8000);

    final record = session.finish(started.add(const Duration(seconds: 18)));
    expect(record.outcome, SessionOutcome.completed);
    expect(record.activeMilliseconds, 10000);
    expect(record.totalMilliseconds, 18000);
    expect(record.repetitions, 0);
  });

  test('Recharge en pause, sans compter le temps pendant la fermeture', () {
    final session = SessionDraft.start(
      const Routine(
        steps: [RoutineStep(exerciseId: 'plank', target: 10)],
        weekdays: {DateTime.wednesday},
      ),
      started,
    );
    session.advance(7000); // 3 s de préparation + 4 s actives
    final restored = SessionDraft.fromJsonString(session.toJsonString());
    expect(restored.paused, isTrue);
    expect(restored.currentActiveMilliseconds, 4000);
    restored.advance(2000);
    expect(restored.currentActiveMilliseconds, 4000);
    restored.togglePause();
    restored.advance(6000);
    expect(
      restored.finish(started.add(const Duration(hours: 1))).activeMilliseconds,
      10000,
    );
  });

  test('Répétitions validées manuellement et passage partiel', () {
    final session = SessionDraft.start(
      const Routine(
        steps: [
          RoutineStep(exerciseId: 'squat', target: 4),
          RoutineStep(exerciseId: 'plank', target: 10),
        ],
        weekdays: {DateTime.wednesday},
      ),
      started,
    );
    session.advance(3000);
    expect(session.currentRepetitions, 0);
    session.changeRepetitions(2);
    session.useEasierVariant();
    session.confirmRepetitions();
    expect(session.results.first.outcome, StepOutcome.partial);
    expect(session.results.first.repetitions, 2);
    expect(session.results.first.target, 4);
    expect(session.results.first.easierVariant, isTrue);
    session.advance(4000); // 3 s de préparation + 1 s active
    session.skip();
    final record = session.finish(started);
    expect(record.outcome, SessionOutcome.partial);
    expect(record.steps.last.outcome, StepOutcome.partial);
    expect(record.activeMilliseconds, 1000);
    expect(record.repetitions, 2);
  });

  test('Un arrêt ne transforme jamais une séance incomplète en réussite', () {
    final session = SessionDraft.start(
      const Routine(
        steps: [RoutineStep(exerciseId: 'plank', target: 10)],
        weekdays: {DateTime.wednesday},
      ),
      started,
    );
    session.advance(5500);
    session.stop();
    final record = session.finish(started.add(const Duration(seconds: 6)));
    expect(record.outcome, SessionOutcome.partial);
    expect(record.steps.single.activeMilliseconds, 2500);
    expect(record.steps.single.outcome, StepOutcome.partial);
    final decoded = SessionRecord.fromJson(
      jsonDecode(jsonEncode(record.withFeeling('Bien').toJson()))
          as Map<String, dynamic>,
    );
    expect(decoded.steps.single.target, 10);
    expect(decoded.feeling, 'Bien');
  });

  test('Les séries ont un repos, puis les anciens objectifs restent figés', () {
    const original = Routine(
      steps: [
        RoutineStep(exerciseId: 'plank', target: 10, sets: 2, restSeconds: 15),
      ],
      weekdays: {DateTime.wednesday},
    );
    final session = SessionDraft.start(original, started);
    expect(session.steps.length, 2);
    session.advance(13000);
    expect(session.phase, SessionPhase.rest);
    expect(session.results.single.target, 10);
    session.advance(15000);
    expect(session.phase, SessionPhase.preparation);
    const changed = Routine(
      steps: [RoutineStep(exerciseId: 'plank', target: 20)],
      weekdays: {DateTime.wednesday},
    );
    expect(changed.steps.single.target, 20);
    session.advance(13000);
    final record = session.finish(started);
    expect(record.outcome, SessionOutcome.completed);
    expect(record.steps.map((step) => step.target), [10, 10]);
    expect(record.activeMilliseconds, 20000);
  });
}
