import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petit_depart/domain/exercise_content.dart';
import 'package:petit_depart/features/exercises/exercise_motion_demo.dart';

void main() {
  testWidgets('Chaque exercice a une pose animée qui change avec le temps', (
    tester,
  ) async {
    for (final guide in exerciseGuides) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ExerciseMotionDemo(guide: guide)),
        ),
      );
      final painted = find.byKey(ValueKey('motion-${guide.id}'));
      final first =
          (tester.widget<CustomPaint>(painted).painter!
                  as ExerciseMotionPainter)
              .progress;
      await tester.pump(const Duration(milliseconds: 800));
      final next =
          (tester.widget<CustomPaint>(painted).painter!
                  as ExerciseMotionPainter)
              .progress;
      expect(next, isNot(first), reason: guide.id);
      expect(tester.takeException(), isNull, reason: guide.id);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('Pause et reprise conservent la position de la démonstration', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ExerciseMotionDemo(guide: guideById('squat'))),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Mettre en pause'));
    await tester.pump();
    final painted = find.byKey(const ValueKey('motion-squat'));
    final paused =
        (tester.widget<CustomPaint>(painted).painter! as ExerciseMotionPainter)
            .progress;
    await tester.pump(const Duration(seconds: 2));
    expect(
      (tester.widget<CustomPaint>(painted).painter! as ExerciseMotionPainter)
          .progress,
      paused,
    );
    await tester.tap(find.text('Reprendre l’animation'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      (tester.widget<CustomPaint>(painted).painter! as ExerciseMotionPainter)
          .progress,
      isNot(paused),
    );
  });

  testWidgets('Le réglage de réduction des animations affiche une pose fixe', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: Scaffold(body: ExerciseMotionDemo(guide: guideById('plank'))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Animation désactivée'), findsOneWidget);
    expect(find.text('Mettre en pause'), findsNothing);
    final painter =
        tester
                .widget<CustomPaint>(find.byKey(const ValueKey('motion-plank')))
                .painter!
            as ExerciseMotionPainter;
    expect(painter.progress, greaterThan(0));
    expect(tester.takeException(), isNull);
  });
}
