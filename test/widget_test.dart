import 'package:flutter_test/flutter_test.dart';
import 'package:petit_depart/main.dart';

void main() {
  testWidgets('Le parcours de découverte reste accessible', (tester) async {
    await tester.pumpWidget(const PetitDepartApp());

    expect(find.text('Un tout petit pas'), findsOneWidget);
    expect(find.text('10 secondes'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Commencer'), 200);
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();
    expect(find.text('Prêt à commencer ?'), findsOneWidget);
    expect(find.textContaining('Le chronomètre'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exercices').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('catalogue d’exercices'), findsOneWidget);
  });
}
