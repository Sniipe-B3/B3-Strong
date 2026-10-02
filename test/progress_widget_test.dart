import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petit_depart/domain/session.dart';
import 'package:petit_depart/features/progress/progress_page.dart';

void main() {
  testWidgets('L’état vide accueille sans pression', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProgressPage(records: const [], now: DateTime(2026, 10, 2)),
        ),
      ),
    );
    expect(find.text('Progrès'), findsOneWidget);
    expect(
      find.text('Votre premier pas peut être tout petit.'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.textContaining('Vos séances apparaîtront ici'), 200);
    expect(find.textContaining('Vos séances apparaîtront ici'), findsOneWidget);
  });

  testWidgets('L’historique montre le résultat et son ancien objectif', (
    tester,
  ) async {
    final saved = SessionRecord(
      id: 'one',
      startedAt: DateTime(2026, 10, 2, 9),
      endedAt: DateTime(2026, 10, 2, 9, 1),
      outcome: SessionOutcome.partial,
      totalMilliseconds: 60000,
      steps: const [
        StepResult(
          exerciseId: 'plank',
          target: 10,
          activeMilliseconds: 5000,
          repetitions: 0,
          outcome: StepOutcome.partial,
          easierVariant: false,
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProgressPage(records: [saved], now: DateTime(2026, 10, 2)),
        ),
      ),
    );
    await tester.scrollUntilVisible(find.text('Historique'), 200);
    await tester.scrollUntilVisible(find.text('02/10/2026'), 200);
    await tester.tap(find.text('02/10/2026'));
    await tester.pumpAndSettle();
    expect(find.text('Partielle'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Objectif d’origine : 10 secondes'),
      200,
    );
    expect(find.text('Objectif d’origine : 10 secondes'), findsOneWidget);
    expect(find.text('Réalisé : 5 s'), findsOneWidget);
  });
}
