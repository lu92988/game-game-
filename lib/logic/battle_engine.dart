import 'dart:math';

import '../data/item_pool.dart';
import '../data/roster.dart';
import '../models/champion.dart';
import '../models/champion_def.dart';
import '../models/champion_role.dart';
import '../models/game_item.dart';

Champion? findChampion(List<Champion> list, String id) {
  for (final c in list) {
    if (c.id == id) return c;
  }
  return null;
}

/// Randomly drafts 3 roster entries, excluding any name in [exclude].
List<ChampionDef> pickThree(List<String> exclude, Random random) {
  final pool = roster.where((c) => !exclude.contains(c.name)).toList();
  final chosen = <ChampionDef>[];
  final copy = [...pool];
  while (chosen.length < 3 && copy.isNotEmpty) {
    final i = random.nextInt(copy.length);
    chosen.add(copy.removeAt(i));
  }
  return chosen;
}

/// Rolls a d10; true if it lands on one of the champion's crit faces.
bool rollCrit(Champion champion, Random random) {
  final face = random.nextInt(10) + 1;
  return champion.critFaces.contains(face);
}

List<GameItem> drawHand(Random random) {
  return List.generate(3, (_) => itemPool[random.nextInt(itemPool.length)]);
}

/// Speed-based initiative: every living champion on both sides, fastest
/// first. Ties are broken randomly (shuffle before the sort) so equal-speed
/// champions don't always resolve in the same order. `List.sort` in Dart
/// isn't guaranteed stable, so ties are broken explicitly by the champion's
/// position in the shuffle rather than relying on sort stability.
List<String> computeRoundOrder(
  List<Champion> player,
  List<Champion> enemy,
  Random random,
) {
  final all = [...player, ...enemy].where((c) => c.alive).toList();
  final shuffled = [...all];
  for (var i = shuffled.length - 1; i > 0; i--) {
    final j = random.nextInt(i + 1);
    final tmp = shuffled[i];
    shuffled[i] = shuffled[j];
    shuffled[j] = tmp;
  }
  final indices = List<int>.generate(shuffled.length, (i) => i);
  indices.sort((a, b) {
    final cmp = shuffled[b].spd.compareTo(shuffled[a].spd);
    if (cmp != 0) return cmp;
    return a.compareTo(b);
  });
  return indices.map((i) => shuffled[i].id).toList();
}

/// A speed tie between champions on opposite sides, already settled by the
/// round's shuffle: [winner] acts before [loser].
class SpeedClash {
  const SpeedClash({required this.winner, required this.loser});

  final Champion winner;
  final Champion loser;
}

/// Finds the coin tosses for every group of equal-SPD champions in [order]
/// that has champions from both sides. Each adjacent pair in such a group
/// gets its own clash, including same-side pairs, so a three-way tie (say
/// two enemy tanks and one of yours) tosses all three rather than leaving
/// one out. A tie among champions on a single side is skipped, since which
/// of your own champions goes first isn't a contest between the two teams.
List<SpeedClash> findSpeedClashes(
  List<String> order,
  List<Champion> player,
  List<Champion> enemy,
) {
  final champs = <Champion>[];
  for (final id in order) {
    final c = findChampion(player, id) ?? findChampion(enemy, id);
    if (c != null) champs.add(c);
  }
  final clashes = <SpeedClash>[];
  var start = 0;
  while (start < champs.length) {
    var end = start + 1;
    while (end < champs.length && champs[end].spd == champs[start].spd) {
      end++;
    }
    final group = champs.sublist(start, end);
    if (group.length > 1 && group.any((c) => c.side != group.first.side)) {
      for (var i = 0; i < group.length - 1; i++) {
        clashes.add(SpeedClash(winner: group[i], loser: group[i + 1]));
      }
    }
    start = end;
  }
  return clashes;
}

/// Walks the initiative order and returns the first living champion who
/// hasn't acted yet this round, or null if the round is complete.
Champion? getCurrentActor(
  List<String> order,
  List<String> acted,
  List<Champion> player,
  List<Champion> enemy,
) {
  for (final id in order) {
    if (acted.contains(id)) continue;
    final c = findChampion(player, id) ?? findChampion(enemy, id);
    if (c != null && c.alive) return c;
  }
  return null;
}

class DamageResult {
  const DamageResult({required this.damage, required this.isCrit});

  final int damage;
  final bool isCrit;
}

/// ```
/// baseStat = (role == Mage || role == Healer) ? MAG : ATK
/// boosted  = baseStat + boost - weaken
/// effDef   = target.DEF + target.defendBuff
///
/// if crit:
///   dmg = max(2, round(boosted * 1.5 - effDef / 2))
///   if target.role == Tank: dmg = max(2, round(dmg / 2))
/// else:
///   dmg = max(1, boosted - effDef)
/// ```
/// Tanks take half damage from crits specifically (not normal hits).
DamageResult calculateDamage(Champion actor, Champion target, Random random) {
  final isCrit = rollCrit(actor, random);
  final baseStat = actor.role.usesMagic ? actor.mag : actor.atk;
  final boosted = baseStat + actor.buffs.boost - actor.buffs.weaken;
  final effDef = target.def + target.buffs.defend;

  int dmg;
  if (isCrit) {
    final rawCrit = max(2, (boosted * 1.5 - effDef / 2).round());
    dmg = target.role == ChampionRole.tank
        ? max(2, (rawCrit / 2).round())
        : rawCrit;
  } else {
    dmg = max(1, boosted - effDef);
  }
  return DamageResult(damage: dmg, isCrit: isCrit);
}
