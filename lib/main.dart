import 'package:flutter/material.dart';

import 'data/routine_store.dart';
import 'data/review_store.dart';
import 'data/session_store.dart';
import 'design_system/app_colors.dart';
import 'domain/routine.dart';
import 'domain/review.dart';
import 'domain/session.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/progress/progress_page.dart';
import 'features/routine/routine_editor_page.dart';
import 'features/review/review_page.dart';
import 'features/session/session_page.dart';

void main() => runApp(const PetitDepartApp());

class PetitDepartApp extends StatelessWidget {
  const PetitDepartApp({
    super.key,
    this.store,
    this.sessionStore,
    this.reviewStore,
    this.today,
  });

  final RoutineStore? store;
  final SessionStore? sessionStore;
  final ReviewStore? reviewStore;
  final DateTime Function()? today;

  @override
  Widget build(BuildContext context) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.accent,
          onPrimary: AppColors.background,
          surface: AppColors.surface,
          onSurface: AppColors.text,
        );

    return MaterialApp(
      title: 'Petit départ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: scheme,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.text,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: AppColors.text,
            fontSize: 34,
            fontWeight: FontWeight.w700,
          ),
          headlineSmall: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: TextStyle(color: AppColors.text),
          bodyMedium: TextStyle(color: AppColors.muted),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.background,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
        ),
      ),
      home: RoutineGate(
        store: store ?? LocalRoutineStore(),
        sessionStore: sessionStore ?? LocalSessionStore(),
        reviewStore: reviewStore ?? LocalReviewStore(),
        today: today ?? DateTime.now,
      ),
    );
  }
}

class RoutineGate extends StatefulWidget {
  const RoutineGate({
    super.key,
    required this.store,
    required this.sessionStore,
    required this.reviewStore,
    required this.today,
  });

  final RoutineStore store;
  final SessionStore sessionStore;
  final ReviewStore reviewStore;
  final DateTime Function() today;

  @override
  State<RoutineGate> createState() => _RoutineGateState();
}

class _RoutineGateState extends State<RoutineGate> {
  Routine? routine;
  SessionDraft? activeSession;
  SessionRecord? lastRecord;
  List<SessionRecord> records = [];
  ReviewSettings reviewSettings = const ReviewSettings();
  SessionRecord? summary;
  bool loading = true;
  bool failed = false;
  bool starting = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      failed = false;
    });
    try {
      final saved = await widget.store.read();
      final active = await widget.sessionStore.readActive();
      final records = await widget.sessionStore.readRecords();
      final reviewSettings = await widget.reviewStore.read();
      if (mounted) {
        setState(() {
          routine = saved;
          activeSession = active;
          this.records = List.of(records);
          this.reviewSettings = reviewSettings;
          lastRecord = records.isEmpty
              ? null
              : (List<SessionRecord>.of(
                  records,
                )..sort((a, b) => b.endedAt.compareTo(a.endedAt))).first;
        });
      }
    } catch (_) {
      if (mounted) setState(() => failed = true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> save(Routine next) async {
    await widget.store.write(next);
    if (mounted) setState(() => routine = next);
  }

  Future<void> edit() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            RoutineEditorPage(initialRoutine: routine!, onSaved: save),
      ),
    );
  }

  Future<void> changeReviewPeriod(int days) async {
    final next = reviewSettings.copyWith(periodDays: days);
    await widget.reviewStore.write(next);
    if (mounted) setState(() => reviewSettings = next);
  }

  Future<void> saveReview(Routine next) async {
    await widget.store.write(next);
    final latest = records.fold<DateTime?>(null, (current, record) {
      return current == null || record.endedAt.isAfter(current)
          ? record.endedAt
          : current;
    });
    final now = widget.today();
    final reviewedAt = latest != null && latest.isAfter(now) ? latest : now;
    final settings = reviewSettings.copyWith(lastReviewedAt: reviewedAt);
    await widget.reviewStore.write(settings);
    if (mounted) {
      setState(() {
        routine = next;
        reviewSettings = settings;
      });
    }
  }

  Future<void> review() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ReviewPage(
          initialRoutine: routine!,
          settings: reviewSettings,
          onPeriodChanged: changeReviewPeriod,
          onSaved: saveReview,
        ),
      ),
    );
  }

  Future<void> start() async {
    if (starting || routine == null) return;
    setState(() => starting = true);
    try {
      final draft = SessionDraft.start(routine!, DateTime.now());
      await widget.sessionStore.writeActive(draft);
      if (mounted) setState(() => activeSession = draft);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de démarrer la séance. Réessayez.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => starting = false);
    }
  }

  void finish(SessionRecord record) {
    setState(() {
      activeSession = null;
      lastRecord = record;
      records = [
        for (final saved in records)
          if (saved.id != record.id) saved,
        record,
      ];
      summary = record;
    });
  }

  Future<void> setFeeling(String feeling) async {
    final current = summary;
    if (current == null) return;
    final updated = current.withFeeling(feeling);
    await widget.sessionStore.saveRecord(updated);
    if (mounted) {
      setState(() {
        summary = updated;
        lastRecord = updated;
        records = [
          for (final saved in records) saved.id == updated.id ? updated : saved,
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (failed) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Impossible de lire votre routine enregistrée.'),
                const SizedBox(height: 16),
                FilledButton(onPressed: load, child: const Text('Réessayer')),
              ],
            ),
          ),
        ),
      );
    }
    final saved = routine;
    if (saved == null) return OnboardingPage(onSaved: save);
    final active = activeSession;
    if (active != null) {
      return SessionPage(
        draft: active,
        store: widget.sessionStore,
        onFinished: finish,
      );
    }
    final finished = summary;
    if (finished != null) {
      return SessionSummaryPage(
        record: finished,
        onFeeling: setFeeling,
        onClose: () => setState(() => summary = null),
      );
    }
    return AppShell(
      routine: saved,
      today: widget.today,
      onEdit: edit,
      onReview: review,
      onStart: start,
      starting: starting,
      lastRecord: lastRecord,
      records: records,
      reviewSettings: reviewSettings,
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.routine,
    required this.today,
    required this.onEdit,
    required this.onReview,
    required this.onStart,
    required this.starting,
    required this.lastRecord,
    required this.records,
    required this.reviewSettings,
  });

  final Routine routine;
  final DateTime Function() today;
  final VoidCallback onEdit;
  final VoidCallback onReview;
  final VoidCallback onStart;
  final bool starting;
  final SessionRecord? lastRecord;
  final List<SessionRecord> records;
  final ReviewSettings reviewSettings;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      TodayPage(
        routine: widget.routine,
        today: widget.today(),
        onEdit: widget.onEdit,
        onReview: widget.onReview,
        onStart: widget.onStart,
        starting: widget.starting,
        lastRecord: widget.lastRecord,
        reviewSchedule: ReviewSchedule.fromRecords(
          widget.records,
          widget.reviewSettings,
        ),
      ),
      const PlaceholderPage(
        icon: Icons.fitness_center_rounded,
        title: 'Exercices',
        message: 'Le catalogue d’exercices arrive à une prochaine étape.',
      ),
      ProgressPage(records: widget.records, now: widget.today()),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: selectedIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent,
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => setState(() => selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today_rounded),
            label: 'Aujourd’hui',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center_rounded),
            label: 'Exercices',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Progrès',
          ),
        ],
      ),
    );
  }
}

class TodayPage extends StatelessWidget {
  const TodayPage({
    super.key,
    required this.routine,
    required this.today,
    required this.onEdit,
    required this.onReview,
    required this.onStart,
    required this.starting,
    required this.lastRecord,
    required this.reviewSchedule,
  });

  final Routine routine;
  final DateTime today;
  final VoidCallback onEdit;
  final VoidCallback onReview;
  final VoidCallback onStart;
  final bool starting;
  final SessionRecord? lastRecord;
  final ReviewSchedule reviewSchedule;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isRestDay = !routine.isScheduledOn(today);
    final estimateMinutes = (routine.estimatedTimedSeconds / 60).ceil();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          children: [
            Row(
              children: [
                const Icon(Icons.wb_sunny_outlined, color: AppColors.accent),
                const SizedBox(width: 10),
                Text(
                  'PETIT DÉPART',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.accent,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Paramètres',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const InfoPage(
                        title: 'Paramètres',
                        message:
                            'Les préférences seront disponibles prochainement.',
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text('Aujourd’hui', style: textTheme.headlineLarge),
            const SizedBox(height: 10),
            Text(
              isRestDay
                  ? 'Aujourd’hui est un jour de repos. À vous de choisir.'
                  : 'Quelques secondes suffisent pour commencer.',
              style: textTheme.bodyLarge?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 28),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.raised,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isRestDay ? 'JOUR DE REPOS' : 'VOTRE ROUTINE',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isRestDay ? 'Le repos compte aussi' : 'Votre petit pas',
                      style: textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isRestDay
                          ? 'Vous pouvez tout de même faire une petite séance si vous en avez envie.'
                          : 'Votre objectif, à votre rythme.',
                    ),
                    const SizedBox(height: 22),
                    for (
                      var index = 0;
                      index < routine.steps.length;
                      index++
                    ) ...[
                      if (index > 0) const Divider(height: 26),
                      ExerciseRow(
                        icon: switch (routine.steps[index].exerciseId) {
                          'plank' => Icons.accessibility_new_rounded,
                          'squat' => Icons.directions_walk_rounded,
                          _ => Icons.directions_run_rounded,
                        },
                        title: exerciseById(routine.steps[index].exerciseId)
                            .name,
                        target: routine.steps[index].sets == 1
                            ? exerciseById(routine.steps[index].exerciseId)
                                  .targetLabel(routine.steps[index].target)
                            : '${routine.steps[index].sets} × ${exerciseById(routine.steps[index].exerciseId).targetLabel(routine.steps[index].target)}',
                      ),
                    ],
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 18,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            routine.hasRepetitions
                                ? 'Durée estimée : variable selon votre rythme'
                                : 'Durée estimée : environ $estimateMinutes min',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: starting ? null : onStart,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                starting
                    ? 'Préparation…'
                    : isRestDay
                    ? 'Faire une petite séance'
                    : 'Commencer',
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onEdit,
              child: const Text('Adapter la séance'),
            ),
            if (lastRecord != null) ...[
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reviewSchedule.isDue(today)
                            ? 'Un bilan, si vous en avez envie'
                            : 'Votre bilan, à votre rythme',
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        reviewSchedule.isDue(today)
                            ? 'La période choisie est passée. À vous de décider pour chaque exercice.'
                            : 'Vous pouvez ajuster vos objectifs quand vous le souhaitez.',
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: onReview,
                        icon: const Icon(Icons.tune_rounded),
                        label: const Text('Faire mon bilan'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (lastRecord != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dernière séance', style: textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        lastRecord!.outcome == SessionOutcome.completed
                            ? 'Terminée'
                            : 'Partielle',
                      ),
                      Text(
                        'Temps actif : ${formatDuration(lastRecord!.activeMilliseconds)} · '
                        'Répétitions : ${lastRecord!.repetitions}',
                      ),
                      Text(
                        'Durée totale : ${formatDuration(lastRecord!.totalMilliseconds)}',
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'À votre rythme. Chaque petit pas compte.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExerciseRow extends StatelessWidget {
  const ExerciseRow({
    super.key,
    required this.icon,
    required this.title,
    required this.target,
  });

  final IconData icon;
  final String title;
  final String target;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.raised,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: AppColors.accent),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        Text(target, style: const TextStyle(color: AppColors.muted)),
      ],
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: AppColors.accent),
            const SizedBox(height: 20),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class InfoPage extends StatelessWidget {
  const InfoPage({super.key, required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
