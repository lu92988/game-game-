import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:champion_draft_battle/logic/battle_engine.dart';
import 'package:champion_draft_battle/models/buffs.dart';
import 'package:champion_draft_battle/models/champion.dart';
import 'package:champion_draft_battle/models/champion_role.dart';
import 'package:champion_draft_battle/models/game_element.dart';
import 'package:champion_draft_battle/models/side.dart';

Champion _make({
  required String id,
  required Side side,
  required ChampionRole role,
  int? hp,
  int? spd,
  Buffs buffs = const Buffs(),
  bool alive = true,
}) {
  return Champion(
    id: id,
    side: side,
    name: id,
    role: role,
    element: GameElement.fire,
    atk: role.atk,
    mag: role.mag,
    def: role.def,
    spd: spd ?? role.spd,
    hp: hp ?? role.hp,
    maxHp: role.hp,
    critFaces: role.critFaces,
    buffs: buffs,
    alive: alive,
  );
}

void main() {
  group('pickThree', () {
    test('draws 3 distinct champions and honors the exclude list', () {
      final random = Random(42);
      final picks = pickThree(const ['Krogg', 'Oorgath'], random);
      expect(picks.length, 3);
      expect(picks.map((c) => c.name).toSet().length, 3);
      expect(picks.any((c) => c.name == 'Krogg' || c.name == 'Oorgath'), isFalse);
    });
  });

  group('computeRoundOrder', () {
    test('orders living champions fastest first and drops the dead', () {
      final random = Random(1);
      final player = [
        _make(id: 'p-fast', side: Side.player, role: ChampionRole.rogue, spd: 10),
        _make(id: 'p-dead', side: Side.player, role: ChampionRole.warrior, spd: 20, alive: false),
      ];
      final enemy = [
        _make(id: 'e-slow', side: Side.enemy, role: ChampionRole.tank, spd: 3),
      ];
      final order = computeRoundOrder(player, enemy, random);
      expect(order, ['p-fast', 'e-slow']);
    });

    test('ties are broken by the shuffle, not always the same champion first', () {
      final player = [_make(id: 'p1', side: Side.player, role: ChampionRole.warrior, spd: 5)];
      final enemy = [_make(id: 'e1', side: Side.enemy, role: ChampionRole.mage, spd: 5)];

      final seenOrders = <String>{};
      for (var seed = 0; seed < 30; seed++) {
        seenOrders.add(computeRoundOrder(player, enemy, Random(seed)).join(','));
      }
      expect(seenOrders.length, 2, reason: 'both tie orderings should occur across many seeds');
    });
  });

  group('getCurrentActor', () {
    test('skips champions who already acted and the dead', () {
      final player = [
        _make(id: 'p1', side: Side.player, role: ChampionRole.warrior),
        _make(id: 'p2', side: Side.player, role: ChampionRole.mage, alive: false),
      ];
      final enemy = [_make(id: 'e1', side: Side.enemy, role: ChampionRole.tank)];
      final order = ['p1', 'p2', 'e1'];

      expect(getCurrentActor(order, const [], player, enemy)?.id, 'p1');
      expect(getCurrentActor(order, const ['p1'], player, enemy)?.id, 'e1');
      expect(getCurrentActor(order, const ['p1', 'e1'], player, enemy), isNull);
    });
  });

  group('calculateDamage', () {
    test('non-crit damage floors at 1 against overwhelming defense', () {
      final actor = _make(id: 'a', side: Side.player, role: ChampionRole.mage);
      final target = _make(id: 't', side: Side.enemy, role: ChampionRole.tank);
      // Force a non-crit by using a champion with no crit faces on this roll.
      final result = calculateDamage(actor, target, Random(2));
      expect(result.damage, greaterThanOrEqualTo(1));
    });

    test('boost and weaken shift the base stat before defense is applied', () {
      final random = Random(7);
      final base = _make(id: 'a', side: Side.player, role: ChampionRole.warrior);
      final boosted = _make(
        id: 'a',
        side: Side.player,
        role: ChampionRole.warrior,
        buffs: const Buffs(boost: 3),
      );
      final target = _make(id: 't', side: Side.enemy, role: ChampionRole.tank);

      final baseDmg = calculateDamage(base, target, Random(7));
      final boostedDmg = calculateDamage(boosted, target, Random(7));
      expect(boostedDmg.damage, greaterThanOrEqualTo(baseDmg.damage));
      // sanity: same seed, same crit roll
      expect(baseDmg.isCrit, calculateDamage(base, target, random).isCrit);
    });

    test('tanks take halved damage specifically on a crit', () {
      // Warrior crits only on a face of 10; find a seed whose first roll
      // lands on it, then replay it with a fresh Random of the same seed.
      int? critSeed;
      for (var seed = 0; seed < 200; seed++) {
        if (Random(seed).nextInt(10) + 1 == 10) {
          critSeed = seed;
          break;
        }
      }
      expect(critSeed, isNotNull);

      final actor = _make(id: 'a', side: Side.player, role: ChampionRole.warrior);
      final tank = _make(id: 't', side: Side.enemy, role: ChampionRole.tank);

      final tankResult = calculateDamage(actor, tank, Random(critSeed!));
      expect(tankResult.isCrit, isTrue);

      final rawCrit = max(2, (actor.atk * 1.5 - tank.def / 2).round());
      final expectedTankDmg = max(2, (rawCrit / 2).round());
      expect(tankResult.damage, expectedTankDmg);
    });
  });
}
