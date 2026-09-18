import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../data/audio_settings.dart';
import '../data/item_pool.dart';
import '../data/sound_effects.dart';
import '../models/champion.dart';
import '../models/champion_def.dart';
import '../models/champion_role.dart';
import '../models/game_element.dart';
import '../models/game_item.dart';
import '../models/side.dart';
import 'battle_engine.dart';

/// Delay before the enemy's turn auto-plays, so the player can read what
/// just happened before the next hit lands.
const enemyActDelay = Duration(milliseconds: 1800);

const maxLogLines = 40;

/// Owns the full battle state and the turn-pacing "effect loop": figures out
/// who's up next, starts a new round when everyone's acted, and auto-plays
/// the enemy's turn after a short delay. Every mutating method ends by
/// calling [_afterUpdate], which is the single source of truth for pacing —
/// mirroring the two `useEffect`s in the original React prototype.
class BattleController extends ChangeNotifier {
  BattleController({required this._playerPicks, Random? random})
    : _random = random ?? Random() {
    _startBattle('The battle begins.');
    _afterUpdate();
  }

  final List<ChampionDef> _playerPicks;
  final Random _random;
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _voicePlayer = AudioPlayer();
  Timer? _enemyTimer;

  late List<Champion> player;
  late List<Champion> enemy;
  late List<String> roundOrder;
  late List<GameItem> hand;
  GameItem? pendingItem;
  late List<String> log;
  late List<String> actedIds;
  Side? winner;

  /// Bumped on every attack so widgets can detect "a new attack happened"
  /// even if the same champion attacks (or is targeted) twice in a row.
  int attackNonce = 0;
  String? lastAttackerId;
  String? lastTargetId;

  /// The attacker's element, so the target's card can color its impact
  /// effect to match what hit it (e.g. a fire attack leaves fire-colored
  /// impact sparks on the target, not just a generic flash).
  GameElement? lastAttackerElement;

  List<Champion> get playerAlive => player.where((c) => c.alive).toList();
  List<Champion> get enemyAlive => enemy.where((c) => c.alive).toList();

  Champion? get currentActor =>
      getCurrentActor(roundOrder, actedIds, player, enemy);

  void _startBattle(String openingLine) {
    final p = <Champion>[
      for (var i = 0; i < _playerPicks.length; i++)
        Champion.fromDef(_playerPicks[i], Side.player, i),
    ];
    final enemyDefs = pickThree(p.map((c) => c.name).toList(), _random);
    final e = <Champion>[
      for (var i = 0; i < enemyDefs.length; i++)
        Champion.fromDef(enemyDefs[i], Side.enemy, i),
    ];

    player = p;
    enemy = e;
    roundOrder = computeRoundOrder(p, e, _random);
    hand = drawHand(_random);
    pendingItem = null;
    log = [openingLine];
    actedIds = [];
    winner = null;
  }

  void resetBattle() {
    _enemyTimer?.cancel();
    _enemyTimer = null;
    _startBattle('A new battle begins.');
    notifyListeners();
    _afterUpdate();
  }

  /// Plays the attacking champion's element sound, if one is mapped and the
  /// asset exists. Missing/unmapped sounds fail silently — sfx is polish,
  /// never something that should block or crash a turn.
  void _playElementSound(GameElement element) {
    final path = sfxFor(element);
    if (path == null) return;
    final volume = AudioSettings.instance.effectiveVolume;
    if (volume <= 0) return;
    unawaited(
      _sfxPlayer.play(AssetSource(path), volume: volume).catchError((_) {}),
    );
  }

  /// Plays the crowd's reaction the instant the battle's outcome is
  /// decided — cheering on a win, booing on a loss. A separate player from
  /// [_sfxPlayer] so it isn't cut off by (or doesn't cut off) whatever
  /// attack sfx just fired on the finishing blow.
  void _playOutcomeVoice({required bool won}) {
    final volume = AudioSettings.instance.effectiveVolume;
    if (volume <= 0) return;
    final path = won ? 'voice/victory.mp3' : 'voice/defeat.mp3';
    unawaited(
      _voicePlayer.play(AssetSource(path), volume: volume).catchError((_) {}),
    );
  }

  void _pushLog(String line) {
    log = [line, ...log];
    if (log.length > maxLogLines) log = log.sublist(0, maxLogLines);
  }

  List<Champion> _sideList(Side side) => side == Side.player ? player : enemy;

  void _setSideList(Side side, List<Champion> list) {
    if (side == Side.player) {
      player = list;
    } else {
      enemy = list;
    }
  }

  void _updateChampion(
    Side side,
    String id,
    Champion Function(Champion) updater,
  ) {
    _setSideList(side, [
      for (final c in _sideList(side)) c.id == id ? updater(c) : c,
    ]);
  }

  void _applyDamage(Side side, String targetId, int amount) {
    _updateChampion(side, targetId, (c) {
      final newHp = max(0, c.hp - amount);
      return c.copyWith(hp: newHp, alive: newHp > 0);
    });
  }

  void _performAttack(Champion actor, Champion target) {
    final actorLive = findChampion(_sideList(actor.side), actor.id)!;
    final targetLive = findChampion(_sideList(target.side), target.id)!;
    final result = calculateDamage(actorLive, targetLive, _random);

    _playElementSound(actorLive.element);
    lastAttackerId = actorLive.id;
    lastTargetId = targetLive.id;
    lastAttackerElement = actorLive.element;
    attackNonce++;
    _applyDamage(target.side, target.id, result.damage);

    // Clear the actor's one-turn boost/weaken after use, and the target's
    // defend buff after it's actually been used to soften this hit.
    _updateChampion(
      actor.side,
      actor.id,
      (c) => c.copyWith(buffs: c.buffs.copyWith(boost: 0, weaken: 0)),
    );
    if (targetLive.buffs.defend > 0) {
      _updateChampion(
        target.side,
        target.id,
        (c) => c.copyWith(buffs: c.buffs.copyWith(defend: 0)),
      );
    }

    final critTag = result.isCrit
        ? (targetLive.role == ChampionRole.tank
              ? ' — CRITICAL HIT (dampened by Tank resilience)!'
              : ' — CRITICAL HIT!')
        : '';
    _pushLog(
      '${actorLive.name} attacks ${targetLive.name} for ${result.damage} damage$critTag.',
    );
  }

  void _performHeal(Champion actor, Champion target) {
    final actorLive = findChampion(_sideList(actor.side), actor.id)!;
    const healAmt = 3;
    _updateChampion(
      target.side,
      target.id,
      (c) => c.copyWith(hp: min(c.maxHp, c.hp + healAmt)),
    );
    _pushLog('${actorLive.name} heals ${target.name} for $healAmt HP.');
  }

  void useItem(GameItem item, Champion target) {
    final actor = currentActor;
    if (actor == null) return;

    switch (item.type) {
      case ItemType.boost:
        _updateChampion(
          target.side,
          target.id,
          (c) => c.copyWith(buffs: c.buffs.copyWith(boost: 3)),
        );
        _pushLog(
          '${actor.name} charges up ${target.name} with ${item.name}. Next attack +3.',
        );
      case ItemType.defend:
        _updateChampion(
          target.side,
          target.id,
          (c) => c.copyWith(buffs: c.buffs.copyWith(defend: 3)),
        );
        _pushLog(
          '${target.name} braces with ${item.name}. Def +3 until the next hit lands.',
        );
      case ItemType.weaken:
        _updateChampion(
          target.side,
          target.id,
          (c) => c.copyWith(buffs: c.buffs.copyWith(weaken: 2)),
        );
        _pushLog('${actor.name} weakens ${target.name}. -2 Atk/Mag next turn.');
    }

    final idx = hand.indexOf(item);
    final newHand = [...hand];
    if (idx >= 0) newHand.removeAt(idx);
    newHand.add(itemPool[_random.nextInt(itemPool.length)]);
    hand = newHand;
  }

  void togglePendingItem(GameItem item) {
    pendingItem = identical(pendingItem, item) ? null : item;
    notifyListeners();
  }

  /// The player acts as whichever champion is currently up in the
  /// initiative order.
  void handleTargetClick(Champion target) {
    if (winner != null) return;
    final actor = currentActor;
    if (actor == null || actor.side != Side.player) return;

    if (pendingItem != null) {
      useItem(pendingItem!, target);
      pendingItem = null;
    } else {
      if (actor.role == ChampionRole.healer && target.side == Side.player) {
        _performHeal(actor, target);
      } else if (target.side == Side.enemy) {
        _performAttack(actor, target);
      } else {
        return;
      }
    }
    actedIds = [...actedIds, actor.id];
    notifyListeners();
    _afterUpdate();
  }

  /// Performs one specific enemy champion's action. Only ever invoked from
  /// the timer scheduled in [_afterUpdate].
  void _enemyAct(String actorId) {
    final actorLive = findChampion(enemy, actorId);
    if (actorLive == null || !actorLive.alive || actedIds.contains(actorId)) {
      return;
    }

    final livingPlayers = player.where((c) => c.alive).toList();
    if (livingPlayers.isEmpty) return;

    final injuredAllies = enemy
        .where((c) => c.alive && c.hp < c.maxHp && c.id != actorLive.id)
        .toList();
    if (actorLive.role == ChampionRole.healer &&
        injuredAllies.isNotEmpty &&
        _random.nextDouble() < 0.6) {
      final weakest = injuredAllies.reduce(
        (a, b) => (a.hp / a.maxHp) <= (b.hp / b.maxHp) ? a : b,
      );
      _performHeal(actorLive, weakest);
    } else {
      final target = livingPlayers[_random.nextInt(livingPlayers.length)];
      _performAttack(actorLive, target);
    }
    actedIds = [...actedIds, actorLive.id];
    notifyListeners();
    _afterUpdate();
  }

  /// Single source of truth for pacing: checks the win condition, advances
  /// to a new round when everyone's acted (looping until a real actor is
  /// found, since a fresh round always has at least one living champion
  /// while there's no winner), and schedules the enemy's action after a
  /// short delay when it's their turn. Cancels any pending enemy timer
  /// first, so a stale timeout can never fire after state has moved on.
  void _afterUpdate() {
    _enemyTimer?.cancel();
    _enemyTimer = null;

    if (winner == null) {
      final pAlive = player.any((c) => c.alive);
      final eAlive = enemy.any((c) => c.alive);
      if (!pAlive) {
        winner = Side.enemy;
        _playOutcomeVoice(won: false);
      } else if (!eAlive) {
        winner = Side.player;
        _playOutcomeVoice(won: true);
      }
    }
    if (winner != null) {
      notifyListeners();
      return;
    }

    var actor = getCurrentActor(roundOrder, actedIds, player, enemy);
    while (actor == null) {
      roundOrder = computeRoundOrder(player, enemy, _random);
      actedIds = [];
      _pushLog('— New round —');
      actor = getCurrentActor(roundOrder, actedIds, player, enemy);
    }

    if (actor.side == Side.enemy) {
      final id = actor.id;
      _enemyTimer = Timer(enemyActDelay, () => _enemyAct(id));
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _enemyTimer?.cancel();
    _sfxPlayer.dispose();
    _voicePlayer.dispose();
    super.dispose();
  }
}
