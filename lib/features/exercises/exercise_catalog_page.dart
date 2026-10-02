import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design_system/app_colors.dart';
import '../../domain/exercise_content.dart';
import 'exercise_illustration.dart';

class ExerciseCatalogPage extends StatefulWidget {
  const ExerciseCatalogPage({super.key, this.onEditRoutine});

  final VoidCallback? onEditRoutine;

  @override
  State<ExerciseCatalogPage> createState() => _ExerciseCatalogPageState();
}

class _ExerciseCatalogPageState extends State<ExerciseCatalogPage> {
  ExerciseCategory? selected;

  @override
  Widget build(BuildContext context) {
    final guides = exerciseGuides
        .where((guide) => selected == null || guide.category == selected)
        .toList();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
          children: [
            Text('Exercices', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            const Text(
              'Des mouvements simples, à découvrir à votre rythme. '
              'Les dessins sont des repères : lisez les consignes avant de commencer.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Si vous avez une blessure, un problème de santé, êtes enceinte ou '
              'ne savez pas si un mouvement vous convient, demandez conseil à un professionnel de santé.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Tous'),
                  selected: selected == null,
                  onSelected: (_) => setState(() => selected = null),
                ),
                for (final category in ExerciseCategory.values)
                  FilterChip(
                    label: Text(category.label),
                    selected: selected == category,
                    onSelected: (_) => setState(() => selected = category),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            for (final guide in guides)
              Card(
                key: ValueKey('guide-${guide.id}'),
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ExerciseDetailPage(
                        guide: guide,
                        onEditRoutine: widget.onEditRoutine,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        ExerciseIllustration(guide: guide, width: 96),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                guide.category.label.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                guide.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                guide.intro,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.directions_run_rounded,
                  color: AppColors.accent,
                ),
                title: const Text('Et pour la course à pied ?'),
                subtitle: const Text(
                  'Quelques repères prudents, sans programme imposé.',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RunningInfoPage(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExerciseDetailPage extends StatelessWidget {
  const ExerciseDetailPage({
    super.key,
    required this.guide,
    this.onEditRoutine,
  });

  final ExerciseGuide guide;
  final VoidCallback? onEditRoutine;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(guide.title)),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
            children: [
              Center(child: ExerciseIllustration(guide: guide, width: 300)),
              const SizedBox(height: 22),
              Text(
                guide.category.label.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.accent,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                guide.title,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(guide.intro),
              const SizedBox(height: 18),
              _section(context, 'Comment faire', [
                for (var index = 0; index < guide.instructions.length; index++)
                  '${index + 1}. ${guide.instructions[index]}',
              ]),
              _section(context, 'Plus facile', [guide.easierVariant]),
              _section(context, 'À savoir', [guide.caution]),
              if (guide.availableInRoutine && onEditRoutine != null) ...[
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      onEditRoutine?.call();
                    });
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Adapter ma routine'),
                ),
              ],
              if (!guide.availableInRoutine) ...[
                const SizedBox(height: 4),
                const Text(
                  'Fiche de découverte : cet étirement n’est pas encore chronométré dans la routine.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
              const SizedBox(height: 16),
              _SourceCard(name: guide.sourceName, url: guide.sourceUrl),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _section(BuildContext context, String title, List<String> lines) => Card(
  margin: const EdgeInsets.only(bottom: 12),
  child: Padding(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 9),
        for (final line in lines) ...[Text(line), const SizedBox(height: 7)],
      ],
    ),
  ),
);

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.name, required this.url});

  final String name;
  final String url;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Source vérifiée',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(name),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lien de la source copié.')),
                );
              }
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copier le lien de la source'),
          ),
        ],
      ),
    ),
  );
}

class RunningInfoPage extends StatelessWidget {
  const RunningInfoPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Course à pied')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
            children: [
              Text(
                'À votre rythme',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 10),
              const Text(
                'Le catalogue propose des mouvements généraux ; ce n’est pas un '
                'programme de préparation à la course ni une prise en charge de blessure.',
              ),
              const SizedBox(height: 18),
              _section(context, 'Avant de courir', [
                'Une marche active ou un jogging très doux de 5 à 10 minutes peut servir d’échauffement.',
                'Augmentez distance et allure progressivement, sans chercher à rattraper une séance manquée.',
              ]),
              _section(context, 'Si quelque chose fait mal', [
                'Ne poursuivez pas la course avec une douleur. Si elle persiste ou vous inquiète, demandez un avis médical ou de kinésithérapie.',
                'Les exercices pour coureurs ne conviennent pas automatiquement à une blessure existante.',
              ]),
              const _SourceCard(
                name: 'NHS — Knee pain and other running injuries',
                url: 'https://www.nhs.uk/live-well/exercise/knee-pain-and-other-running-injuries/',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
