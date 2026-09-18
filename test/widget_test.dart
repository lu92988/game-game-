import 'package:flutter_test/flutter_test.dart';

import 'package:champion_draft_battle/main.dart';

void main() {
  testWidgets('Menu leads to the draft screen, which lets the player pick 3 champions and start a battle', (
    tester,
  ) async {
    await tester.pumpWidget(const ChampionDraftBattleApp());
    await tester.pump();

    expect(find.text('Enter the Arena'), findsOneWidget);
    await tester.tap(find.text('Enter the Arena'));
    await tester.pumpAndSettle();

    expect(find.text('Choose Your Champions'), findsOneWidget);
    expect(find.text('Pick 3 — 0/3 selected'), findsOneWidget);

    await tester.ensureVisible(find.text('Krogg'));
    await tester.tap(find.text('Krogg'));
    await tester.ensureVisible(find.text('Robotoman'));
    await tester.tap(find.text('Robotoman'));
    await tester.ensureVisible(find.text('Thundric'));
    await tester.tap(find.text('Thundric'));
    await tester.pump();

    expect(find.text('Pick 3 — 3/3 selected'), findsOneWidget);

    await tester.ensureVisible(find.text('Begin Battle'));
    await tester.tap(find.text('Begin Battle'));
    await tester.pumpAndSettle();

    expect(find.text('Champion Draft Battle'), findsWidgets);
    expect(find.text('Opponent'), findsOneWidget);
    expect(find.text('Your Team'), findsOneWidget);
    expect(find.text('Hand'), findsOneWidget);
  });
}
