import 'dart:math';

import '../data/item_pool.dart';
import '../data/roster.dart';
import '../models/champion.dart';
import '../models/champion_def.dart';
import '../models/champion_role.dart';
import '../models/game_element.dart';
import '../models/game_item.dart';
import '../models/side.dart';

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
///
/// [clashResults] remembers earlier Speed Clashes (see [clashKey]): once two
/// opposing champions have tossed, the winner always acts before the loser
/// whenever they tie again, whatever the shuffle says.
List<String> computeRoundOrder(
  List<Champion> player,
  List<Champion> enemy,
  Random random, {
  Map<String, String> clashResults = const {},
}) {
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
  final sorted = [for (final i in indices) shuffled[i]];

  final order = <String>[];
  var start = 0;
  while (start < sorted.length) {
    var end = start + 1;
    while (end < sorted.length && sorted[end].spd == sorted[start].spd) {
      end++;
    }
    order.addAll(_orderTieGroup(sorted.sublist(start, end), clashResults));
    start = end;
  }
  return order;
}

/// Key for a pair of champions in the clash results, the same whichever
/// order the two ids are given in.
String clashKey(String a, String b) => a.compareTo(b) <= 0 ? '$a|$b' : '$b|$a';

/// Orders one group of equal-SPD champions (already in shuffle order) so
/// that every remembered clash result is respected: repeatedly takes the
/// first champion that nobody left in the group is known to beat.
List<String> _orderTieGroup(
  List<Champion> group,
  Map<String, String> clashResults,
) {
  if (group.length < 2 || clashResults.isEmpty) {
    return [for (final c in group) c.id];
  }
  final remaining = [...group];
  final ordered = <String>[];
  while (remaining.isNotEmpty) {
    final pick = remaining.firstWhere(
      (c) => !remaining.any(
        (o) => !identical(o, c) && clashResults[clashKey(c.id, o.id)] == o.id,
      ),
      orElse: () => remaining.first,
    );
    remaining.remove(pick);
    ordered.add(pick.id);
  }
  return ordered;
}

/// A Speed Clash between two opposing champions tied on SPD: [winner] acts
/// before [loser].
class SpeedClash {
  const SpeedClash({required this.winner, required this.loser});

  final Champion winner;
  final Champion loser;
}

/// The Speed Clashes that open on [actor]'s turn: one for every opposing
/// champion who is tied with [actor] on SPD, still alive, hasn't acted this
/// round, and has never clashed with [actor] before. [actor] is next in the
/// round order, so it wins each of them. A pair only ever clashes once per
/// battle; later meetings follow the remembered result in [clashResults].
List<SpeedClash> clashesForTurn(
  Champion actor,
  List<Champion> player,
  List<Champion> enemy,
  List<String> acted,
  Map<String, String> clashResults,
) {
  final opponents = actor.side == Side.player ? enemy : player;
  return [
    for (final o in opponents)
      if (o.alive &&
          o.spd == actor.spd &&
          !acted.contains(o.id) &&
          !clashResults.containsKey(clashKey(actor.id, o.id)))
        SpeedClash(winner: actor, loser: o),
  ];
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
  const DamageResult({
    required this.damage,
    required this.isCrit,
    this.matchup = ElementMatchup.neutral,
  });

  final int damage;
  final bool isCrit;
  final ElementMatchup matchup;
}

/// Damage multiplier for the attacker's element against the target's.
const double elementAdvantageMultiplier = 1.5;
const double elementDisadvantageMultiplier = 0.75;

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
///
/// then, by element matchup (Water > Fire > Wind > Earth > Lightning > Water):
///   advantage    -> dmg = round(dmg * 1.5)
///   disadvantage -> dmg = round(dmg * 0.75), never below the usual minimum
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

  final matchup = actor.element.matchupAgainst(target.element);
  final minDamage = isCrit ? 2 : 1;
  switch (matchup) {
    case ElementMatchup.advantage:
      dmg = max(dmg, (dmg * elementAdvantageMultiplier).round());
    case ElementMatchup.disadvantage:
      dmg = max(minDamage, (dmg * elementDisadvantageMultiplier).round());
    case ElementMatchup.neutral:
      break;
  }
  return DamageResult(damage: dmg, isCrit: isCrit, matchup: matchup);
}
