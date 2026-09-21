import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:champion_draft_battle/data/roster.dart';
import 'package:champion_draft_battle/logic/battle_controller.dart';
import 'package:champion_draft_battle/logic/battle_engine.dart';
import 'package:champion_draft_battle/models/champion_role.dart';
import 'package:champion_draft_battle/models/side.dart';

void main() {
  testWidgets(
    'each pair clashes once, on the winner\'s turn, and stays settled',
    (tester) async {
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
        final seenPairs = <String>{};
        // Who won each pair's toss, so we can check later rounds follow it.
        final winners = <String, String>{};

        for (var step = 0; step < 200 && controller.winner == null; step++) {
          final clash = controller.currentClash;
          if (clash != null) {
            clashesSeen++;
            if (controller.actedIds.isNotEmpty) clashesMidRound++;
            final key = clashKey(clash.winner.id, clash.loser.id);
            expect(
              seenPairs.add(key),
              isTrue,
              reason: 'seed $seed: $key clashed twice',
            );
            winners[key] = clash.winner.id;
            expect(
              clash.winner.id,
              controller.currentActor?.id,
              reason: 'seed $seed, step $step',
            );
            controller.dismissClash();
            continue;
          }

          // Whenever two clashed champions are both still waiting to act,
          // the remembered winner must be ahead of the loser in the order.
          for (final entry in winners.entries) {
            final ids = entry.key.split('|');
            final loserId = ids.first == entry.value ? ids.last : ids.first;
            final wi = controller.roundOrder.indexOf(entry.value);
            final li = controller.roundOrder.indexOf(loserId);
            if (wi >= 0 && li >= 0) {
              expect(wi < li, isTrue, reason: 'seed $seed, ${entry.key}');
            }
          }

          if (controller.currentActor?.side == Side.player) {
            controller.handleTargetClick(controller.enemyAlive.first);
          } else {
            await tester.pump(enemyActDelay);
          }
        }
        controller.dispose();
      }

      expect(clashesSeen, greaterThan(0));
      // Tosses happen partway through the round, on the tied champions' turn,
      // not only in a batch before anyone has acted.
      expect(clashesMidRound, greaterThan(0));
    },
  );
}
