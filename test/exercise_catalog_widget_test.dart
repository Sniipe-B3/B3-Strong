import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petit_depart/features/exercises/exercise_catalog_page.dart';
import 'package:petit_depart/features/exercises/exercise_illustration.dart';

void main() {
  testWidgets('Catalogue et fiches lisibles sur un écran de 390 pixels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ExerciseCatalogPage())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Exercices'), findsOneWidget);
    expect(find.byType(ExerciseIllustration), findsWidgets);
    await tester.tap(find.text('Mobilité'));
    await tester.pumpAndSettle();
    expect(find.text('Cercles d’épaules'), findsOneWidget);
    expect(find.text('Rotation douce du cou'), findsOneWidget);
    expect(find.text('Planche'), findsNothing);
    await tester.tap(find.text('Rotation douce du cou'));
    await tester.pumpAndSettle();
    expect(find.text('Comment faire'), findsOneWidget);
    expect(find.text('Plus facile'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Source vérifiée'), 180);
    expect(find.text('Source vérifiée'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Étirement'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Étirement du mollet'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('pas encore chronométré'),
      180,
    );
    expect(find.textContaining('pas encore chronométré'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Le complément course à pied reste une fiche prudente', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ExerciseCatalogPage())),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Et pour la course à pied ?'),
      200,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -150));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Et pour la course à pied ?'));
    await tester.pumpAndSettle();
    expect(find.text('À votre rythme'), findsOneWidget);
    expect(find.text('Si quelque chose fait mal'), findsOneWidget);
  });

  testWidgets('Une fiche peut ouvrir l’adaptation de la routine', (
    tester,
  ) async {
    var editCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExerciseCatalogPage(onEditRoutine: () => editCalls++),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Planche'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Adapter ma routine'), 180);
    await tester.drag(find.byType(ListView).last, const Offset(0, -150));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adapter ma routine'));
    await tester.pumpAndSettle();
    expect(editCalls, 1);
    expect(find.text('Exercices'), findsOneWidget);
  });
}
