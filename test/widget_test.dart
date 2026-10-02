import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petit_depart/data/routine_store.dart';
import 'package:petit_depart/data/session_store.dart';
import 'package:petit_depart/domain/routine.dart';
import 'package:petit_depart/domain/session.dart';
import 'package:petit_depart/main.dart';

class MemoryRoutineStore implements RoutineStore {
  Routine? routine;

  @override
  Future<Routine?> read() async => routine;

  @override
  Future<void> write(Routine value) async => routine = value;
}

class MemorySessionStore implements SessionStore {
  String? activeSnapshot;
  final List<SessionRecord> records = [];

  @override
  Future<SessionDraft?> readActive() async => activeSnapshot == null
      ? null
      : SessionDraft.fromJsonString(activeSnapshot!);

  @override
  Future<void> writeActive(SessionDraft draft) async =>
      activeSnapshot = draft.toJsonString();

  @override
  Future<void> clearActive() async => activeSnapshot = null;

  @override
  Future<List<SessionRecord>> readRecords() async => records;

  @override
  Future<void> saveRecord(SessionRecord record) async {
    records.removeWhere((saved) => saved.id == record.id);
    records.add(record);
  }
}

void main() {
  testWidgets('Une routine choisie reste disponible au redémarrage', (
    tester,
  ) async {
    final store = MemoryRoutineStore();
    final sessionStore = MemorySessionStore();
    DateTime today() => DateTime(2026, 9, 28); // lundi
    await tester.pumpWidget(
      PetitDepartApp(store: store, sessionStore: sessionStore, today: today),
    );
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

    await tester.pumpWidget(
      PetitDepartApp(store: store, sessionStore: sessionStore, today: today),
    );
    await tester.pumpAndSettle();
    expect(find.text('Votre petit pas'), findsOneWidget);
    expect(find.text('15 secondes'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Adapter la séance'), 200);
    await tester.drag(find.byType(ListView).first, const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adapter la séance'));
    await tester.pumpAndSettle();
    expect(find.text('Votre prochaine séance'), findsOneWidget);
    await tester.tap(find.byTooltip('Augmenter objectif Planche'));
    await tester.pumpAndSettle();
    expect(store.routine!.steps.first.target, 15);
    await tester.tap(find.text('Voir les changements'));
    await tester.pumpAndSettle();
    expect(find.text('Vérifier la routine'), findsOneWidget);
    await tester.tap(find.text('Enregistrer la routine'));
    await tester.pumpAndSettle();
    expect(store.routine!.steps.first.target, 20);
    expect(store.routine!.steps.length, 3);
    expect(find.text('20 secondes'), findsOneWidget);
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
        sessionStore: MemorySessionStore(),
        today: () => DateTime(2026, 9, 29), // mardi
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Le repos compte aussi'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Faire une petite séance'), 200);
    await tester.tap(find.text('Faire une petite séance'));
    await tester.pumpAndSettle();
    expect(find.text('Votre séance'), findsOneWidget);
    expect(find.text('PRÉPAREZ-VOUS'), findsOneWidget);
  });

  testWidgets('Une séance arrêtée reste partielle après redémarrage', (
    tester,
  ) async {
    final routineStore = MemoryRoutineStore()
      ..routine = const Routine(
        steps: [RoutineStep(exerciseId: 'squat', target: 4)],
        weekdays: {DateTime.wednesday},
      );
    final sessions = MemorySessionStore();
    await tester.pumpWidget(
      PetitDepartApp(
        store: routineStore,
        sessionStore: sessions,
        today: () => DateTime(2026, 9, 30),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Commencer'), 200);
    await tester.tap(find.text('Commencer'));
    await tester.pump();
    expect(find.text('À VOTRE RYTHME'), findsOneWidget);
    await tester.tap(find.byTooltip('Ajouter une répétition'));
    await tester.pump();
    await tester.tap(find.text('Arrêter'));
    await tester.pump();
    await tester.tap(find.text('Enregistrer et arrêter'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Séance partielle enregistrée'), findsOneWidget);
    expect(sessions.records.single.repetitions, 1);
    expect(sessions.records.single.outcome, SessionOutcome.partial);
    await tester.drag(find.byType(ListView).last, const Offset(0, -220));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retour à aujourd’hui'));
    await tester.pump();
    await tester.pumpWidget(
      PetitDepartApp(
        store: routineStore,
        sessionStore: sessions,
        today: () => DateTime(2026, 9, 30),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Dernière séance'), 200);
    expect(find.text('Dernière séance'), findsOneWidget);
    expect(find.text('Partielle'), findsOneWidget);
  });
}
