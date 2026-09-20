import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:champion_draft_battle/data/roster.dart';
import 'package:champion_draft_battle/logic/battle_controller.dart';
import 'package:champion_draft_battle/models/champion_role.dart';
import 'package:champion_draft_battle/models/side.dart';

void main() {
  testWidgets('a speed clash only opens on the turn its winner is up next', (
    tester,
  ) async {
    final picks = roster
        .where((d) => d.role == ChampionRole.tank)
        .take(3)
        .toList();
    var clashesSeen = 0;
    var clashesMidRound = 0;

    for (var seed = 0; seed < 40; seed++) {
      final controller = BattleController(
        playerPicks: picks,
        random: Random(seed),
      );

      // Play the battle out. Whenever a clash is on screen it must belong to
      // the champion who is about to act, and it must not be shown up front
      // for champions further down the order.
      for (var step = 0; step < 120 && controller.winner == null; step++) {
        final clash = controller.currentClash;
        if (clash != null) {
          clashesSeen++;
          if (controller.actedIds.isNotEmpty) clashesMidRound++;
          expect(
            clash.winner.id,
            controller.currentActor?.id,
            reason: 'seed $seed, step $step',
          );
          controller.dismissClash();
        } else if (controller.currentActor?.side == Side.player) {
          controller.handleTargetClick(controller.enemyAlive.first);
        } else {
          await tester.pump(enemyActDelay);
        }
      }
      controller.dispose();
    }

    expect(clashesSeen, greaterThan(0));
    // The point of the change: tosses happen partway through the round, not
    // only in a batch before anyone has acted.
    expect(clashesMidRound, greaterThan(0));
  });
}
