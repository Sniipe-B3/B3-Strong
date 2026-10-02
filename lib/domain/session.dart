import 'dart:convert';
import 'dart:math' as math;

import 'routine.dart';

enum SessionPhase { preparation, timed, repetitions, rest, finished }

enum StepOutcome { completed, partial, skipped }

enum SessionOutcome { completed, partial }

class StepResult {
  const StepResult({
    required this.exerciseId,
    required this.target,
    required this.activeMilliseconds,
    required this.repetitions,
    required this.outcome,
    required this.easierVariant,
  });

  final String exerciseId;
  final int target;
  final int activeMilliseconds;
  final int repetitions;
  final StepOutcome outcome;
  final bool easierVariant;

  Map<String, Object> toJson() => {
    'exerciseId': exerciseId,
    'target': target,
    'activeMilliseconds': activeMilliseconds,
    'repetitions': repetitions,
    'outcome': outcome.name,
    'easierVariant': easierVariant,
  };

  factory StepResult.fromJson(Map<String, dynamic> json) => StepResult(
    exerciseId: json['exerciseId'] as String,
    target: json['target'] as int,
    activeMilliseconds: json['activeMilliseconds'] as int,
    repetitions: json['repetitions'] as int,
    outcome: StepOutcome.values.byName(json['outcome'] as String),
    easierVariant: json['easierVariant'] as bool,
  );
}

class SessionRecord {
  const SessionRecord({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.outcome,
    required this.totalMilliseconds,
    required this.steps,
    this.feeling,
  });

  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final SessionOutcome outcome;
  final int totalMilliseconds;
  final List<StepResult> steps;
  final String? feeling;

  int get activeMilliseconds =>
      steps.fold(0, (sum, step) => sum + step.activeMilliseconds);
  int get repetitions => steps.fold(0, (sum, step) => sum + step.repetitions);

  SessionRecord withFeeling(String value) => SessionRecord(
    id: id,
    startedAt: startedAt,
    endedAt: endedAt,
    outcome: outcome,
    totalMilliseconds: totalMilliseconds,
    steps: steps,
    feeling: value,
  );

  Map<String, Object?> toJson() => {
    'version': 1,
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt.toIso8601String(),
    'outcome': outcome.name,
    'totalMilliseconds': totalMilliseconds,
    'steps': steps.map((step) => step.toJson()).toList(),
    'feeling': feeling,
  };

  factory SessionRecord.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) throw const FormatException('Version inconnue');
    return SessionRecord(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: DateTime.parse(json['endedAt'] as String),
      outcome: SessionOutcome.values.byName(json['outcome'] as String),
      totalMilliseconds: json['totalMilliseconds'] as int,
      steps: (json['steps'] as List)
          .map((item) => StepResult.fromJson(item as Map<String, dynamic>))
          .toList(),
      feeling: json['feeling'] as String?,
    );
  }
}

/// Mutable, testable rules for one session. Time advances only when the UI
/// explicitly calls [advance]; reloading never invents elapsed exercise time.
class SessionDraft {
  SessionDraft._({
    required this.id,
    required this.startedAt,
    required this.steps,
    required this.results,
    required this.index,
    required this.phase,
    required this.paused,
    required this.preparationMilliseconds,
    required this.restMilliseconds,
    required this.currentActiveMilliseconds,
    required this.currentRepetitions,
    required this.totalMilliseconds,
    required this.easierVariant,
  });

  factory SessionDraft.start(Routine routine, DateTime now) {
    final steps = <RoutineStep>[
      for (final step in routine.steps)
        for (var setIndex = 0; setIndex < step.sets; setIndex++)
          RoutineStep(
            exerciseId: step.exerciseId,
            target: step.target,
            restSeconds: setIndex + 1 < step.sets ? step.restSeconds : 0,
          ),
    ];
    return SessionDraft._(
      id: now.microsecondsSinceEpoch.toString(),
      startedAt: now,
      steps: steps,
      results: [],
      index: 0,
      phase: _phaseFor(steps.first),
      paused: false,
      preparationMilliseconds: 0,
      restMilliseconds: 0,
      currentActiveMilliseconds: 0,
      currentRepetitions: 0,
      totalMilliseconds: 0,
      easierVariant: false,
    );
  }

  final String id;
  final DateTime startedAt;
  final List<RoutineStep> steps;
  final List<StepResult> results;
  int index;
  SessionPhase phase;
  bool paused;
  int preparationMilliseconds;
  int restMilliseconds;
  int currentActiveMilliseconds;
  int currentRepetitions;
  int totalMilliseconds;
  bool easierVariant;

  RoutineStep get currentStep => steps[index];
  ExerciseSpec get currentExercise => exerciseById(currentStep.exerciseId);
  bool get isFinished => phase == SessionPhase.finished;
  int get remainingSeconds => math.max(
    0,
    (currentStep.target * 1000 - currentActiveMilliseconds + 999) ~/ 1000,
  );
  int get preparationSeconds =>
      math.max(0, (3000 - preparationMilliseconds + 999) ~/ 1000);
  int get remainingRestSeconds => math.max(
    0,
    (steps[index - 1].restSeconds * 1000 - restMilliseconds + 999) ~/ 1000,
  );

  static SessionPhase _phaseFor(RoutineStep step) =>
      exerciseById(step.exerciseId).unit == ExerciseUnit.seconds
      ? SessionPhase.preparation
      : SessionPhase.repetitions;

  void advance(int milliseconds) {
    if (milliseconds <= 0 || isFinished) return;
    totalMilliseconds += milliseconds;
    if (paused || phase == SessionPhase.repetitions) return;
    var remaining = milliseconds;
    if (phase == SessionPhase.rest) {
      final restLeft = steps[index - 1].restSeconds * 1000 - restMilliseconds;
      final used = math.min(remaining, restLeft);
      restMilliseconds += used;
      remaining -= used;
      if (restMilliseconds == steps[index - 1].restSeconds * 1000) {
        phase = _phaseFor(currentStep);
      }
    }
    if (phase == SessionPhase.preparation) {
      final preparationLeft = 3000 - preparationMilliseconds;
      final used = math.min(remaining, preparationLeft);
      preparationMilliseconds += used;
      remaining -= used;
      if (preparationMilliseconds == 3000) phase = SessionPhase.timed;
    }
    if (phase == SessionPhase.timed && remaining > 0) {
      final targetMilliseconds = currentStep.target * 1000;
      currentActiveMilliseconds = math.min(
        targetMilliseconds,
        currentActiveMilliseconds + remaining,
      );
      if (currentActiveMilliseconds == targetMilliseconds) {
        _finishCurrent(StepOutcome.completed);
      }
    }
  }

  void togglePause() {
    if (!isFinished) paused = !paused;
  }

  void useEasierVariant() {
    if (!isFinished) easierVariant = true;
  }

  void changeRepetitions(int delta) {
    if (isFinished || paused || phase != SessionPhase.repetitions) return;
    currentRepetitions = (currentRepetitions + delta).clamp(0, 999);
  }

  void confirmRepetitions() {
    if (isFinished || paused || phase != SessionPhase.repetitions) return;
    _finishCurrent(
      currentRepetitions >= currentStep.target
          ? StepOutcome.completed
          : currentRepetitions > 0
          ? StepOutcome.partial
          : StepOutcome.skipped,
    );
  }

  void skip() {
    if (isFinished) return;
    if (phase == SessionPhase.rest) {
      skipRest();
      return;
    }
    _finishCurrent(
      currentActiveMilliseconds > 0 || currentRepetitions > 0
          ? StepOutcome.partial
          : StepOutcome.skipped,
    );
  }

  void stop() {
    if (isFinished) return;
    if (phase == SessionPhase.rest) {
      phase = SessionPhase.finished;
      return;
    }
    _finishCurrent(
      currentActiveMilliseconds > 0 || currentRepetitions > 0
          ? StepOutcome.partial
          : StepOutcome.skipped,
      stopSession: true,
    );
  }

  void skipRest() {
    if (phase == SessionPhase.rest) phase = _phaseFor(currentStep);
  }

  void _finishCurrent(StepOutcome outcome, {bool stopSession = false}) {
    final restAfterStep = currentStep.restSeconds;
    results.add(
      StepResult(
        exerciseId: currentStep.exerciseId,
        target: currentStep.target,
        activeMilliseconds: currentActiveMilliseconds,
        repetitions: currentRepetitions,
        outcome: outcome,
        easierVariant: easierVariant,
      ),
    );
    if (stopSession || index + 1 == steps.length) {
      phase = SessionPhase.finished;
      return;
    }
    index++;
    phase = restAfterStep > 0 ? SessionPhase.rest : _phaseFor(currentStep);
    paused = false;
    preparationMilliseconds = 0;
    restMilliseconds = 0;
    currentActiveMilliseconds = 0;
    currentRepetitions = 0;
    easierVariant = false;
  }

  SessionRecord finish(DateTime now) {
    if (!isFinished) throw StateError('Séance encore active');
    return SessionRecord(
      id: id,
      startedAt: startedAt,
      endedAt: now,
      outcome:
          results.length == steps.length &&
              results.every((result) => result.outcome == StepOutcome.completed)
          ? SessionOutcome.completed
          : SessionOutcome.partial,
      totalMilliseconds: totalMilliseconds,
      steps: List.unmodifiable(results),
    );
  }

  String toJsonString() => jsonEncode({
    'version': 1,
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'steps': steps.map((step) => step.toJson()).toList(),
    'results': results.map((result) => result.toJson()).toList(),
    'index': index,
    'phase': phase.name,
    'paused': paused,
    'preparationMilliseconds': preparationMilliseconds,
    'restMilliseconds': restMilliseconds,
    'currentActiveMilliseconds': currentActiveMilliseconds,
    'currentRepetitions': currentRepetitions,
    'totalMilliseconds': totalMilliseconds,
    'easierVariant': easierVariant,
  });

  factory SessionDraft.fromJsonString(
    String value, {
    bool pauseOnRestore = true,
  }) {
    final json = jsonDecode(value) as Map<String, dynamic>;
    if (json['version'] != 1) throw const FormatException('Version inconnue');
    final steps = (json['steps'] as List)
        .map((item) => RoutineStep.fromJson(item as Map<String, dynamic>))
        .toList();
    if (steps.isEmpty) throw const FormatException('Séance vide');
    return SessionDraft._(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      steps: steps,
      results: (json['results'] as List)
          .map((item) => StepResult.fromJson(item as Map<String, dynamic>))
          .toList(),
      index: json['index'] as int,
      phase: SessionPhase.values.byName(json['phase'] as String),
      // A page reload or browser restart always resumes in pause.
      paused: pauseOnRestore ? true : json['paused'] as bool,
      preparationMilliseconds: json['preparationMilliseconds'] as int,
      restMilliseconds: json['restMilliseconds'] as int? ?? 0,
      currentActiveMilliseconds: json['currentActiveMilliseconds'] as int,
      currentRepetitions: json['currentRepetitions'] as int,
      totalMilliseconds: json['totalMilliseconds'] as int,
      easierVariant: json['easierVariant'] as bool,
    );
  }
}
