import 'session.dart';

/// A recorded session belongs to the local calendar day on which it ended.
/// A zero-effort partial session is recorded, but is not an active day.
class ProgressSummary {
  const ProgressSummary({
    required this.weekStart,
    required this.sessionsThisWeek,
    required this.activeDaysThisWeek,
    required this.activeMillisecondsThisWeek,
    required this.totalMillisecondsThisWeek,
    required this.repetitionsThisWeek,
    required this.history,
    required this.message,
    required this.milestones,
  });

  final DateTime weekStart;
  final int sessionsThisWeek;
  final int activeDaysThisWeek;
  final int activeMillisecondsThisWeek;
  final int totalMillisecondsThisWeek;
  final int repetitionsThisWeek;
  final List<SessionRecord> history;
  final String message;
  final List<String> milestones;

  factory ProgressSummary.fromRecords(
    List<SessionRecord> records,
    DateTime now,
  ) {
    final localNow = now.toLocal();
    final today = DateTime(localNow.year, localNow.month, localNow.day);
    final monday = DateTime(
      today.year,
      today.month,
      today.day - today.weekday + 1,
    );
    final nextMonday = DateTime(monday.year, monday.month, monday.day + 7);
    final history = List<SessionRecord>.of(records)
      ..sort((a, b) => b.endedAt.compareTo(a.endedAt));
    final week = history.where((record) {
      final ended = record.endedAt.toLocal();
      return !ended.isBefore(monday) && ended.isBefore(nextMonday);
    }).toList();
    final activeDays = <String>{};
    for (final record in week) {
      if (record.activeMilliseconds > 0 || record.repetitions > 0) {
        final ended = record.endedAt.toLocal();
        activeDays.add('${ended.year}-${ended.month}-${ended.day}');
      }
    }
    final meaningful = history
        .where(
          (record) => record.activeMilliseconds > 0 || record.repetitions > 0,
        )
        .toList();
    final lastActive = meaningful.isEmpty
        ? null
        : meaningful.first.endedAt.toLocal();
    final daysSinceLastActive = lastActive == null
        ? 0
        : DateTime.utc(today.year, today.month, today.day)
              .difference(
                DateTime.utc(lastActive.year, lastActive.month, lastActive.day),
              )
              .inDays;
    final message = meaningful.isEmpty
        ? 'Votre premier pas peut être tout petit.'
        : daysSinceLastActive >= 7
        ? 'Heureux de vous retrouver. Reprenez à votre rythme.'
        : 'Chaque petit pas compte, même une séance partielle.';
    return ProgressSummary(
      weekStart: monday,
      sessionsThisWeek: week.length,
      activeDaysThisWeek: activeDays.length,
      activeMillisecondsThisWeek: week.fold(
        0,
        (sum, record) => sum + record.activeMilliseconds,
      ),
      totalMillisecondsThisWeek: week.fold(
        0,
        (sum, record) => sum + record.totalMilliseconds,
      ),
      repetitionsThisWeek: week.fold(
        0,
        (sum, record) => sum + record.repetitions,
      ),
      history: List.unmodifiable(history),
      message: message,
      milestones: [
        if (meaningful.isNotEmpty) 'Premier petit pas',
        if (meaningful.length >= 3) 'Trois séances à votre rythme',
      ],
    );
  }
}
