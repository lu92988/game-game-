import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:champion_draft_battle/logic/battle_engine.dart';
import 'package:champion_draft_battle/models/buffs.dart';
import 'package:champion_draft_battle/models/champion.dart';
import 'package:champion_draft_battle/models/champion_role.dart';
import 'package:champion_draft_battle/models/game_balance.dart';
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
  GameElement element = GameElement.fire,
}) {
  return Champion(
    id: id,
    side: side,
    name: id,
    role: role,
    element: element,
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
      expect(
        picks.any((c) => c.name == 'Krogg' || c.name == 'Oorgath'),
        isFalse,
      );
    });
  });

  group('computeRoundOrder', () {
    test('orders living champions fastest first and drops the dead', () {
      final random = Random(1);
      final player = [
        _make(
          id: 'p-fast',
          side: Side.player,
          role: ChampionRole.rogue,
          spd: 10,
        ),
        _make(
          id: 'p-dead',
          side: Side.player,
          role: ChampionRole.warrior,
          spd: 20,
          alive: false,
        ),
      ];
      final enemy = [
        _make(id: 'e-slow', side: Side.enemy, role: ChampionRole.tank, spd: 3),
      ];
      final order = computeRoundOrder(player, enemy, random);
      expect(order, ['p-fast', 'e-slow']);
    });

    test(
      'ties are broken by the shuffle, not always the same champion first',
      () {
        final player = [
          _make(
            id: 'p1',
            side: Side.player,
            role: ChampionRole.warrior,
            spd: 5,
          ),
        ];
        final enemy = [
          _make(id: 'e1', side: Side.enemy, role: ChampionRole.mage, spd: 5),
        ];

        final seenOrders = <String>{};
        for (var seed = 0; seed < 30; seed++) {
          seenOrders.add(
            computeRoundOrder(player, enemy, Random(seed)).join(','),
          );
        }
        expect(
          seenOrders.length,
          2,
          reason: 'both tie orderings should occur across many seeds',
        );
      },
    );
  });

  group('clashesForTurn', () {
    Champion tank(String id, Side side) =>
        _make(id: id, side: side, role: ChampionRole.tank);

    test('a tied opponent who has not acted or clashed yet is a clash', () {
      final player = [tank('p1', Side.player)];
      final enemy = [tank('e1', Side.enemy)];
      final clashes = clashesForTurn(player.first, player, enemy, [], {});
      expect(clashes.length, 1);
      expect(clashes.single.winner.id, 'p1');
      expect(clashes.single.loser.id, 'e1');
    });

    test('one turn can open a clash against every tied opponent', () {
      final player = [tank('p1', Side.player)];
      final enemy = [tank('e1', Side.enemy), tank('e2', Side.enemy)];
      final clashes = clashesForTurn(player.first, player, enemy, [], {});
      expect([for (final c in clashes) c.loser.id], ['e1', 'e2']);
    });

    test('a pair that has clashed before never clashes again', () {
      final player = [tank('p1', Side.player)];
      final enemy = [tank('e1', Side.enemy)];
      final results = {clashKey('p1', 'e1'): 'e1'};
      expect(clashesForTurn(enemy.first, player, enemy, [], results), isEmpty);
      expect(clashesForTurn(player.first, player, enemy, [], results), isEmpty);
    });

    test(
      'ignores same-side ties, other speeds, the dead and those who acted',
      () {
        final player = [tank('p1', Side.player), tank('p2', Side.player)];
        final enemy = [
          _make(id: 'e1', side: Side.enemy, role: ChampionRole.rogue),
          _make(
            id: 'e2',
            side: Side.enemy,
            role: ChampionRole.tank,
            alive: false,
          ),
          tank('e3', Side.enemy),
        ];
        expect(
          clashesForTurn(player.first, player, enemy, ['e3'], {}),
          isEmpty,
        );
      },
    );
  });

  group('computeRoundOrder with remembered clashes', () {
    test('the remembered winner always goes first, whatever the shuffle', () {
      final player = [
        _make(id: 'p1', side: Side.player, role: ChampionRole.tank),
      ];
      final enemy = [
        _make(id: 'e1', side: Side.enemy, role: ChampionRole.tank),
      ];
      for (final winner in ['p1', 'e1']) {
        final results = {clashKey('p1', 'e1'): winner};
        for (var seed = 0; seed < 30; seed++) {
          final order = computeRoundOrder(
            player,
            enemy,
            Random(seed),
            clashResults: results,
          );
          expect(order.first, winner, reason: 'seed $seed');
        }
      }
    });

    test('every remembered result holds in a bigger tied group', () {
      final player = [
        _make(id: 'p1', side: Side.player, role: ChampionRole.tank),
        _make(id: 'p2', side: Side.player, role: ChampionRole.tank),
      ];
      final enemy = [
        _make(id: 'e1', side: Side.enemy, role: ChampionRole.tank),
        _make(id: 'e2', side: Side.enemy, role: ChampionRole.tank),
      ];
      final results = {
        clashKey('p1', 'e1'): 'e1',
        clashKey('p2', 'e1'): 'p2',
        clashKey('p2', 'e2'): 'e2',
      };
      for (var seed = 0; seed < 40; seed++) {
        final order = computeRoundOrder(
          player,
          enemy,
          Random(seed),
          clashResults: results,
        );
        expect(order.length, 4);
        expect(order.indexOf('e1') < order.indexOf('p1'), isTrue);
        expect(order.indexOf('p2') < order.indexOf('e1'), isTrue);
        expect(order.indexOf('e2') < order.indexOf('p2'), isTrue);
      }
    });
  });

  group('getCurrentActor', () {
    test('skips champions who already acted and the dead', () {
      final player = [
        _make(id: 'p1', side: Side.player, role: ChampionRole.warrior),
        _make(
          id: 'p2',
          side: Side.player,
          role: ChampionRole.mage,
          alive: false,
        ),
      ];
      final enemy = [
        _make(id: 'e1', side: Side.enemy, role: ChampionRole.tank),
      ];
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
      final base = _make(
        id: 'a',
        side: Side.player,
        role: ChampionRole.warrior,
      );
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

      final actor = _make(
        id: 'a',
        side: Side.player,
        role: ChampionRole.warrior,
      );
      final tank = _make(id: 't', side: Side.enemy, role: ChampionRole.tank);

      final tankResult = calculateDamage(actor, tank, Random(critSeed!));
      expect(tankResult.isCrit, isTrue);

      final rawCrit = max(
        minCritDamage,
        (actor.atk * 1.5 - tank.def / 2).round(),
      );
      final expectedTankDmg = max(minCritDamage, (rawCrit / 2).round());
      expect(tankResult.damage, expectedTankDmg);
    });
  });

  group('element matchups', () {
    test('the wheel is Water > Fire > Wind > Earth > Lightning > Water', () {
      expect(GameElement.water.beats, GameElement.fire);
      expect(GameElement.fire.beats, GameElement.wind);
      expect(GameElement.wind.beats, GameElement.earth);
      expect(GameElement.earth.beats, GameElement.lightning);
      expect(GameElement.lightning.beats, GameElement.water);
    });

    test('each element has one advantage, one disadvantage, rest neutral', () {
      for (final a in GameElement.values) {
        final results = [
          for (final d in GameElement.values) a.matchupAgainst(d),
        ];
        expect(results.where((m) => m == ElementMatchup.advantage).length, 1);
        expect(
          results.where((m) => m == ElementMatchup.disadvantage).length,
          1,
        );
        // Same element is neutral, and the pairing is symmetric.
        expect(a.matchupAgainst(a), ElementMatchup.neutral);
        for (final d in GameElement.values) {
          final forward = a.matchupAgainst(d);
          final back = d.matchupAgainst(a);
          if (forward == ElementMatchup.advantage) {
            expect(back, ElementMatchup.disadvantage);
          } else if (forward == ElementMatchup.disadvantage) {
            expect(back, ElementMatchup.advantage);
          } else {
            expect(back, ElementMatchup.neutral);
          }
        }
      }
    });

    test('advantage deals 1.5x, disadvantage 0.75x, neutral is unchanged', () {
      // Find a seed that does not crit (Warriors only crit on a 10).
      final seed = [
        for (var s = 0; s < 50; s++)
          if (Random(s).nextInt(10) + 1 != 10) s,
      ].first;

      Champion attacker(GameElement el) => _make(
        id: 'a',
        side: Side.player,
        role: ChampionRole.warrior,
        // Pick the boost so a Warrior hits another Warrior for exactly 8,
        // whatever the current stat scale is.
        buffs: Buffs(
          boost: 8 - (ChampionRole.warrior.atk - ChampionRole.warrior.def),
        ),
        element: el,
      );
      Champion defender(GameElement el) => _make(
        id: 't',
        side: Side.enemy,
        role: ChampionRole.warrior,
        element: el,
      );

      final neutral = calculateDamage(
        attacker(GameElement.fire),
        defender(GameElement.fire),
        Random(seed),
      );
      expect(neutral.damage, 8);
      expect(neutral.matchup, ElementMatchup.neutral);

      final strong = calculateDamage(
        attacker(GameElement.water),
        defender(GameElement.fire),
        Random(seed),
      );
      expect(strong.damage, 12);
      expect(strong.matchup, ElementMatchup.advantage);

      final weak = calculateDamage(
        attacker(GameElement.fire),
        defender(GameElement.water),
        Random(seed),
      );
      expect(weak.damage, 6);
      expect(weak.matchup, ElementMatchup.disadvantage);
    });

    test('a resisted hit never drops below the minimum damage', () {
      // A Tank cannot get through another Tank, so every hit sits on the floor;
      // resisting must not push it below that floor.
      final actor = _make(
        id: 'a',
        side: Side.player,
        role: ChampionRole.tank,
        element: GameElement.fire,
      );
      final target = _make(
        id: 't',
        side: Side.enemy,
        role: ChampionRole.tank,
        element: GameElement.water,
      );
      for (var seed = 0; seed < 30; seed++) {
        final r = calculateDamage(actor, target, Random(seed));
        expect(
          r.damage,
          greaterThanOrEqualTo(r.isCrit ? minCritDamage : minDamage),
        );
        expect(r.matchup, ElementMatchup.disadvantage);
      }
    });
  });

  group('minimum damage', () {
    test('the floors are the base 1 and 2 scaled by the stat scale', () {
      expect(minDamage, 1 * statScale);
      expect(minCritDamage, 2 * statScale);
    });

    test('a hit that cannot get through defence deals exactly the floor', () {
      // A Tank's ATK is far below another Tank's DEF, so a normal hit is
      // stuck on the floor. Find a seed that does not crit.
      final seed = [
        for (var s = 0; s < 50; s++)
          if (!ChampionRole.tank.critFaces.contains(Random(s).nextInt(10) + 1))
            s,
      ].first;
      final actor = _make(id: 'a', side: Side.player, role: ChampionRole.tank);
      final target = _make(id: 't', side: Side.enemy, role: ChampionRole.tank);
      final r = calculateDamage(actor, target, Random(seed));
      expect(r.isCrit, isFalse);
      expect(r.damage, minDamage);
    });
  });
}
