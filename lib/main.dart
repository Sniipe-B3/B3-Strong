import 'package:flutter/material.dart';

import 'data/routine_store.dart';
import 'design_system/app_colors.dart';
import 'domain/routine.dart';
import 'features/onboarding/onboarding_page.dart';

void main() => runApp(const PetitDepartApp());

class PetitDepartApp extends StatelessWidget {
  const PetitDepartApp({super.key, this.store, this.today});

  final RoutineStore? store;
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
        today: today ?? DateTime.now,
      ),
    );
  }
}

class RoutineGate extends StatefulWidget {
  const RoutineGate({super.key, required this.store, required this.today});

  final RoutineStore store;
  final DateTime Function() today;

  @override
  State<RoutineGate> createState() => _RoutineGateState();
}

class _RoutineGateState extends State<RoutineGate> {
  Routine? routine;
  bool loading = true;
  bool failed = false;

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
      if (mounted) setState(() => routine = saved);
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
        builder: (_) => OnboardingPage(initialRoutine: routine, onSaved: save),
      ),
    );
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
    return AppShell(routine: saved, today: widget.today, onEdit: edit);
  }
}

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.routine,
    required this.today,
    required this.onEdit,
  });

  final Routine routine;
  final DateTime Function() today;
  final VoidCallback onEdit;

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
      ),
      const PlaceholderPage(
        icon: Icons.fitness_center_rounded,
        title: 'Exercices',
        message: 'Le catalogue d’exercices arrive à une prochaine étape.',
      ),
      const PlaceholderPage(
        icon: Icons.insights_rounded,
        title: 'Progrès',
        message: 'Votre historique apparaîtra ici après vos premières séances.',
      ),
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
  });

  final Routine routine;
  final DateTime today;
  final VoidCallback onEdit;

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
                        target: exerciseById(routine.steps[index].exerciseId)
                            .targetLabel(routine.steps[index].target),
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
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SessionPreviewPage(routine: routine),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(isRestDay ? 'Faire une petite séance' : 'Commencer'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onEdit,
              child: const Text('Adapter la séance'),
            ),
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

class SessionPreviewPage extends StatelessWidget {
  const SessionPreviewPage({super.key, required this.routine});

  final Routine routine;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Votre séance')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_circle_outline_rounded,
                  size: 76,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 20),
                Text(
                  'Prêt à commencer ?',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  routine.steps
                      .map((step) {
                        final exercise = exerciseById(step.exerciseId);
                        return '${exercise.name} : ${exercise.targetLabel(step.target)}';
                      })
                      .join('\n'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, height: 1.7),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Le chronomètre et l’enregistrement des séances arrivent à la prochaine étape.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Retour à aujourd’hui'),
                ),
              ],
            ),
          ),
        ),
      ),
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
