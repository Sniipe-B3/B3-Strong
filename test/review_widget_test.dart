import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petit_depart/domain/review.dart';
import 'package:petit_depart/domain/routine.dart';
import 'package:petit_depart/features/review/review_page.dart';

void main() {
  testWidgets(
    'Les choix indépendants ne sont appliqués qu’après confirmation',
    (tester) async {
      const original = Routine(
        steps: [
          RoutineStep(exerciseId: 'plank', target: 10),
          RoutineStep(exerciseId: 'squat', target: 2),
          RoutineStep(exerciseId: 'step_jack', target: 3),
        ],
        weekdays: {DateTime.friday},
      );
      Routine? saved;
      int? period;
      await tester.pumpWidget(
        MaterialApp(
          home: ReviewPage(
            initialRoutine: original,
            settings: const ReviewSettings(),
            onPeriodChanged: (days) async => period = days,
            onSaved: (value) async => saved = value,
          ),
        ),
      );
      await tester.tap(find.text('Tous les 7 jours'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tous les 14 jours').last);
      await tester.pumpAndSettle();
      expect(period, 14);
      await tester.ensureVisible(find.byTooltip('Augmenter Planche'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Augmenter Planche'));
      await tester.scrollUntilVisible(find.byTooltip('Réduire Squats'), 180);
      await tester.tap(find.byTooltip('Réduire Squats'));
      await tester.scrollUntilVisible(
        find.byTooltip('Reporter Jumping jack sans saut'),
        180,
      );
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Reporter Jumping jack sans saut'));
      expect(saved, isNull);
      await tester.tap(find.text('Voir mon choix'));
      await tester.pumpAndSettle();
      expect(find.text('10 secondes → 15 secondes'), findsOneWidget);
      expect(find.text('2 répétitions → 1 répétition'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Reporté au prochain bilan'),
        150,
      );
      expect(find.text('Reporté au prochain bilan'), findsOneWidget);
      expect(saved, isNull);
      await tester.tap(find.text('Confirmer mon bilan'));
      await tester.pumpAndSettle();
      expect(saved!.steps.map((step) => step.target), [15, 1, 3]);
      expect(original.steps.map((step) => step.target), [10, 2, 3]);
    },
  );
}
