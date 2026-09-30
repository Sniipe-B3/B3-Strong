import 'package:flutter/material.dart';

void main() => runApp(const PetitDepartApp());

class AppColors {
  static const background = Color(0xFF17191B);
  static const surface = Color(0xFF24272A);
  static const raised = Color(0xFF303438);
  static const text = Color(0xFFF3F0E7);
  static const muted = Color(0xFFB8B9B5);
  static const accent = Color(0xFFF4CC46);
}

class PetitDepartApp extends StatelessWidget {
  const PetitDepartApp({super.key});

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
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const TodayPage(),
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
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
              'Quelques secondes suffisent pour commencer.',
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
                      child: const Text(
                        'ROUTINE DE DÉCOUVERTE',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Un tout petit pas', style: textTheme.headlineSmall),
                    const SizedBox(height: 6),
                    const Text('Un exemple pour découvrir l’application.'),
                    const SizedBox(height: 22),
                    const ExerciseRow(
                      icon: Icons.accessibility_new_rounded,
                      title: 'Planche',
                      target: '10 secondes',
                    ),
                    const Divider(height: 26),
                    const ExerciseRow(
                      icon: Icons.directions_walk_rounded,
                      title: 'Squats',
                      target: '2 répétitions',
                    ),
                    const SizedBox(height: 22),
                    const Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 18,
                          color: AppColors.muted,
                        ),
                        SizedBox(width: 8),
                        Text('Durée estimée : moins de 2 min'),
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
                  builder: (_) => const SessionPreviewPage(),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Commencer'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const InfoPage(
                    title: 'Adapter la séance',
                    message: 'Vous pourrez bientôt choisir vos exercices et vos objectifs.',
                  ),
                ),
              ),
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
  const SessionPreviewPage({super.key});

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
                const Text(
                  'Planche : 10 secondes\nSquats : 2 répétitions',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, height: 1.7),
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
