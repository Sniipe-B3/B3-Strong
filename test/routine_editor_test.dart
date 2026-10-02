import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petit_depart/domain/routine.dart';
import 'package:petit_depart/features/routine/routine_editor_page.dart';

void main() {
  testWidgets('Ajouter, retirer et réordonner avant confirmation', (
    tester,
  ) async {
    const initial = Routine(
      steps: [
        RoutineStep(exerciseId: 'plank', target: 10),
        RoutineStep(exerciseId: 'squat', target: 2),
      ],
      weekdays: {DateTime.monday},
    );
    Routine? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: RoutineEditorPage(
          initialRoutine: initial,
          onSaved: (value) async => saved = value,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Retirer Squats'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Ajouter un exercice'), 200);
    await tester.tap(find.text('Ajouter un exercice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Squats').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byTooltip('Monter Squats'), 200);
    await tester.tap(find.byTooltip('Monter Squats'));
    await tester.pumpAndSettle();
    expect(saved, isNull);
    await tester.tap(find.text('Voir les changements'));
    await tester.pumpAndSettle();
    expect(find.text('Routine actuelle'), findsOneWidget);
    await tester.tap(find.text('Enregistrer la routine'));
    await tester.pumpAndSettle();
    expect(saved!.steps.map((step) => step.exerciseId), ['squat', 'plank']);
    expect(initial.steps.map((step) => step.exerciseId), ['plank', 'squat']);
  });

  testWidgets('Séries et repos sont enregistrés après aperçu', (tester) async {
    const initial = Routine(
      steps: [RoutineStep(exerciseId: 'plank', target: 10)],
      weekdays: {DateTime.monday},
    );
    Routine? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: RoutineEditorPage(
          initialRoutine: initial,
          onSaved: (value) async => saved = value,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Augmenter séries Planche'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Augmenter repos Planche'));
    await tester.tap(find.text('Voir les changements'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('2 séries de 10 secondes · 15 s de repos'),
      findsOneWidget,
    );
    await tester.tap(find.text('Enregistrer la routine'));
    await tester.pumpAndSettle();
    expect(saved!.steps.single.sets, 2);
    expect(saved!.steps.single.restSeconds, 15);
  });
}
