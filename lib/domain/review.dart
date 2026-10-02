import 'dart:convert';

import 'routine.dart';
import 'session.dart';

enum ReviewChoice { keep, increase, reduce, postpone }

class ReviewSettings {
  const ReviewSettings({this.periodDays = 7, this.lastReviewedAt});

  final int periodDays;
  final DateTime? lastReviewedAt;

  ReviewSettings copyWith({int? periodDays, DateTime? lastReviewedAt}) =>
      ReviewSettings(
        periodDays: periodDays ?? this.periodDays,
        lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      );

  String toJsonString() => jsonEncode({
    'version': 1,
    'periodDays': periodDays,
    'lastReviewedAt': lastReviewedAt?.toIso8601String(),
  });

  factory ReviewSettings.fromJsonString(String value) {
    final json = jsonDecode(value);
    if (json is! Map<String, dynamic> || json['version'] != 1) {
      throw const FormatException('Bilan invalide');
    }
    final periodDays = json['periodDays'];
    final rawDate = json['lastReviewedAt'];
    if (periodDays is! int ||
        !reviewPeriods.contains(periodDays) ||
        rawDate != null && rawDate is! String) {
      throw const FormatException('Préférences de bilan invalides');
    }
    return ReviewSettings(
      periodDays: periodDays,
      lastReviewedAt: rawDate == null ? null : DateTime.parse(rawDate),
    );
  }
}

const reviewPeriods = [7, 14, 28];

// Compare calendar dates in UTC to avoid losing a day at daylight-saving time.
int _calendarDay(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

class ReviewSchedule {
  const ReviewSchedule({required this.firstSession, required this.dueAt});

  final DateTime? firstSession;
  final DateTime? dueAt;

  bool isDue(DateTime now) =>
      dueAt != null && _calendarDay(now) >= _calendarDay(dueAt!);

  static ReviewSchedule fromRecords(
    List<SessionRecord> records,
    ReviewSettings settings,
  ) {
    final eligible =
        records
            .where(
              (record) =>
                  settings.lastReviewedAt == null ||
                  record.endedAt.isAfter(settings.lastReviewedAt!),
            )
            .toList()
          ..sort((a, b) => a.endedAt.compareTo(b.endedAt));
    if (eligible.isEmpty) {
      return const ReviewSchedule(firstSession: null, dueAt: null);
    }
    final first = eligible.first.endedAt.toLocal();
    final start = settings.lastReviewedAt?.toLocal();
    final anchor = start != null && start.isAfter(first) ? start : first;
    return ReviewSchedule(
      firstSession: first,
      dueAt: DateTime(
        anchor.year,
        anchor.month,
        anchor.day + settings.periodDays,
      ),
    );
  }
}

int reviewedTarget(RoutineStep step, ReviewChoice choice) {
  final unit = exerciseById(step.exerciseId).unit;
  final increment = unit == ExerciseUnit.seconds ? 5 : 1;
  return switch (choice) {
    ReviewChoice.increase => (step.target + increment).clamp(1, 300),
    ReviewChoice.reduce => (step.target - increment).clamp(1, 300),
    ReviewChoice.keep || ReviewChoice.postpone => step.target,
  };
}

Routine applyReview(Routine routine, List<ReviewChoice> choices) {
  if (routine.steps.length != choices.length) {
    throw ArgumentError('Un choix est requis par exercice');
  }
  return Routine(
    steps: [
      for (var index = 0; index < routine.steps.length; index++)
        RoutineStep(
          exerciseId: routine.steps[index].exerciseId,
          target: reviewedTarget(routine.steps[index], choices[index]),
          sets: routine.steps[index].sets,
          restSeconds: routine.steps[index].restSeconds,
        ),
    ],
    weekdays: {...routine.weekdays},
  );
}
