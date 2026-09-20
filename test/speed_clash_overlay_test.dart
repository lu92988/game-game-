import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:champion_draft_battle/logic/battle_engine.dart';
import 'package:champion_draft_battle/models/champion.dart';
import 'package:champion_draft_battle/models/champion_role.dart';
import 'package:champion_draft_battle/models/game_element.dart';
import 'package:champion_draft_battle/models/side.dart';
import 'package:champion_draft_battle/widgets/speed_clash_overlay.dart';

Champion _champ(String name, Side side) => Champion(
  id: name,
  side: side,
  name: name,
  role: ChampionRole.rogue,
  element: GameElement.fire,
  atk: 6,
  mag: 2,
  def: 3,
  spd: 10,
  hp: 4,
  maxHp: 4,
  critFaces: const [8, 9, 10],
);

Widget _host(SpeedClash clash, VoidCallback onDone) => MaterialApp(
  home: Scaffold(
    body: SpeedClashOverlay(clash: clash, onDone: onDone),
  ),
);

void main() {
  final clash = SpeedClash(
    winner: _champ('Enemy Rogue', Side.enemy),
    loser: _champ('Player Rogue', Side.player),
  );

  testWidgets('shows both champions, then reveals the winner and finishes', (
    tester,
  ) async {
    var done = 0;
    await tester.pumpWidget(_host(clash, () => done++));

    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('SPEED CLASH'), findsOneWidget);
    expect(find.text('Enemy Rogue'), findsOneWidget);
    expect(find.text('Player Rogue'), findsOneWidget);
    expect(find.text('Enemy Rogue acts first!'), findsOneWidget);
    expect(done, 0);

    await tester.pump(const Duration(milliseconds: 3900));
    expect(done, 0);

    await tester.pump(const Duration(milliseconds: 500));
    expect(done, 1);
  });

  testWidgets('tapping skips straight to done, exactly once', (tester) async {
    var done = 0;
    await tester.pumpWidget(_host(clash, () => done++));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byType(SpeedClashOverlay));
    await tester.pump();
    expect(done, 1);

    await tester.pump(const Duration(seconds: 6));
    expect(done, 1);
  });
}
