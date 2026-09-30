import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petit_depart/data/routine_store.dart';
import 'package:petit_depart/domain/routine.dart';
import 'package:petit_depart/main.dart';

class MemoryRoutineStore implements RoutineStore {
  Routine? routine;

  @override
  Future<Routine?> read() async => routine;

  @override
  Future<void> write(Routine value) async => routine = value;
}

void main() {
  testWidgets('Une routine choisie reste disponible au redémarrage', (
    tester,
  ) async {
    final store = MemoryRoutineStore();
    DateTime today() => DateTime(2026, 9, 28); // lundi
    await tester.pumpWidget(PetitDepartApp(store: store, today: today));
    await tester.pumpAndSettle();

    expect(find.text('On commence petit.'), findsOneWidget);
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Petite routine'), 200);
    await tester.tap(find.text('Petite routine'));
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(find.text('10 secondes'), findsOneWidget);
    await tester.tap(find.byTooltip('Augmenter Planche'));
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    expect(store.routine!.steps.length, 3);
    expect(store.routine!.steps.first.target, 15);
    expect(find.text('Votre petit pas'), findsOneWidget);
    expect(find.text('15 secondes'), findsOneWidget);

    await tester.pumpWidget(PetitDepartApp(store: store, today: today));
    await tester.pumpAndSettle();
    expect(find.text('Votre petit pas'), findsOneWidget);
    expect(find.text('15 secondes'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Adapter la séance'), 200);
    await tester.drag(find.byType(ListView).first, const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adapter la séance'));
    await tester.pumpAndSettle();
    expect(find.text('Votre premier mouvement'), findsOneWidget);
    await tester.tap(find.text('Squats').first);
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tous les jours'));
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();
    expect(store.routine!.steps.single.exerciseId, 'squat');
    expect(store.routine!.weekdays.length, 7);
    expect(find.text('Squats'), findsOneWidget);
  });

  testWidgets('Un jour de repos garde une séance volontaire disponible', (
    tester,
  ) async {
    final store = MemoryRoutineStore()
      ..routine = const Routine(
        steps: [RoutineStep(exerciseId: 'plank', target: 10)],
        weekdays: {DateTime.monday},
      );
    await tester.pumpWidget(
      PetitDepartApp(
        store: store,
        today: () => DateTime(2026, 9, 29), // mardi
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Le repos compte aussi'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Faire une petite séance'), 200);
    await tester.tap(find.text('Faire une petite séance'));
    await tester.pumpAndSettle();
    expect(find.text('Prêt à commencer ?'), findsOneWidget);
  });
}
