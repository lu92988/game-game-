import 'package:champion_draft_battle/models/champion.dart';
import 'package:champion_draft_battle/models/champion_role.dart';
import 'package:champion_draft_battle/models/game_element.dart';
import 'package:champion_draft_battle/models/side.dart';
import 'package:champion_draft_battle/widgets/champion_card.dart';
import 'package:champion_draft_battle/widgets/element_effect.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Champion _fireChampion(String id) => Champion(
  id: id,
  side: Side.player,
  name: 'Test Fire',
  role: ChampionRole.warrior,
  element: GameElement.fire,
  atk: 8,
  mag: 2,
  def: 6,
  spd: 4,
  hp: 7,
  maxHp: 7,
  critFaces: const [10],
);

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets(
    'attack effect overlay appears only for the attacking card, only during its animation window',
    (tester) async {
      final attacker = _fireChampion('player-0');

      await tester.pumpWidget(
        _wrap(
          ChampionCard(
            champ: attacker,
            attackNonce: 0,
            attackerId: null,
            targetId: null,
          ),
        ),
      );
      expect(find.byType(ElementEffectOverlay), findsNothing);

      // Bump the nonce with this champion as the attacker.
      await tester.pumpWidget(
        _wrap(
          ChampionCard(
            champ: attacker,
            attackNonce: 1,
            attackerId: 'player-0',
            targetId: 'enemy-0',
          ),
        ),
      );
      await tester.pump(); // let didUpdateWidget's forward(from: 0) take effect
      expect(find.byType(ElementEffectOverlay), findsOneWidget);

      // Mid-animation.
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.byType(ElementEffectOverlay), findsOneWidget);

      // Past the 1800ms animation duration, the overlay should be gone again.
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.byType(ElementEffectOverlay), findsNothing);
    },
  );

  testWidgets(
    'a card that is neither attacker nor target never shows the effect overlay',
    (tester) async {
      final bystander = _fireChampion('player-1');

      await tester.pumpWidget(
        _wrap(
          ChampionCard(
            champ: bystander,
            attackNonce: 1,
            attackerId: 'player-0',
            targetId: 'enemy-0',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ElementEffectOverlay), findsNothing);
    },
  );

  testWidgets(
    'the target shows an impact burst (not the cast overlay) while the attacker does not',
    (tester) async {
      final target = _fireChampion('enemy-0');

      // No attacker element known yet — no burst.
      await tester.pumpWidget(
        _wrap(
          ChampionCard(
            champ: target,
            attackNonce: 1,
            attackerId: 'player-0',
            targetId: 'enemy-0',
            attackerElement: null,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ImpactBurstOverlay), findsNothing);

      // With an attacker element supplied, the target shows the burst instead
      // of the attacker-style cast overlay.
      await tester.pumpWidget(
        _wrap(
          ChampionCard(
            champ: target,
            attackNonce: 2,
            attackerId: 'player-0',
            targetId: 'enemy-0',
            attackerElement: GameElement.lightning,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ImpactBurstOverlay), findsOneWidget);
      expect(find.byType(ElementEffectOverlay), findsNothing);
    },
  );
}
