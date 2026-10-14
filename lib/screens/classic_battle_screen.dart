import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/attack_effects.dart';
import '../data/battle_sprites.dart';
import '../data/roster.dart';
import '../logic/battle_controller.dart';
import '../models/champion.dart';
import '../models/champion_def.dart';
import '../models/champion_role.dart';
import '../models/game_element.dart';
import '../models/game_item.dart';
import '../models/side.dart';
import '../theme/battle_colors.dart';
import '../theme/body_style.dart';
import '../widgets/ornate_divider.dart';
import '../widgets/pixel_sprite_view.dart';
import '../widgets/speed_clash_overlay.dart';

/// A test of a side-view, menu-driven battle in the style of the SNES-era
/// RPGs: sprites facing each other across a battlefield, command windows
/// and floating damage numbers. The windows and type use the game's own
/// look (Cinzel headings, Neohellenic body text, dark panels trimmed in
/// gold) rather than copying any one game. It runs on the exact same
/// [BattleController] as the card battle, so every rule (turn order, Speed
/// Clash, elements, items) is unchanged; only the presentation differs.
class ClassicBattleScreen extends StatefulWidget {
  const ClassicBattleScreen({
    super.key,
    required this.playerPicks,
    this.enemyPicks,
  });

  /// The fixed teams of the "Classic Battle (test)" menu entry.
  factory ClassicBattleScreen.testBattle() => ClassicBattleScreen(
    playerPicks: _defs(const ['Robotoman', 'Thunderboy', 'Krogg']),
    enemyPicks: _defs(const ['Demon Knight', 'Friedrich Blitzberg', 'Riptide']),
  );

  static List<ChampionDef> _defs(List<String> names) => [
    for (final n in names) roster.firstWhere((d) => d.name == n),
  ];

  final List<ChampionDef> playerPicks;

  /// A fixed enemy team; when null the enemy is drafted at random.
  final List<ChampionDef>? enemyPicks;

  @override
  State<ClassicBattleScreen> createState() => _ClassicBattleScreenState();
}

enum _MenuMode { main, attackTarget, items, itemTarget }

class _Popup {
  _Popup(this.key, this.champId, this.text, this.color, this.glow);

  final int key;
  final String champId;
  final String text;
  final Color color;
  final Color glow;
}

class _ClassicBattleScreenState extends State<ClassicBattleScreen>
    with TickerProviderStateMixin {
  late final BattleController _controller;

  /// The battlefield art behind this battle, picked at random.
  final String _backdrop = _backdrops[Random().nextInt(_backdrops.length)];
  static const _backdrops = [
    'assets/backdrops/castle.jpg',
    'assets/backdrops/burning_city.jpg',
    'assets/backdrops/forest.jpg',
  ];
  late final AnimationController _act = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  /// Loops forever to drive the idle row of animated sprite sheets.
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  /// Drives the item-use animation (user gathers magic, it flies to the
  /// target), separate from attacks.
  late final AnimationController _item = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  /// Drives a healer's heal animation.
  late final AnimationController _heal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  static const _normalHit = Duration(milliseconds: 900);

  /// Knockouts play in slow motion.
  static const _knockoutHit = Duration(milliseconds: 1600);

  _MenuMode _mode = _MenuMode.main;
  int _lastNonce = 0;
  String? _fxAttacker;
  String? _fxTarget;
  Color _fxColor = Colors.white;
  GameElement? _fxElement;

  /// The last hit was big enough to shake the screen (critical, super
  /// effective or a knockout).
  bool _fxBig = false;
  bool _fxKill = false;
  bool _fxDefended = false;

  /// The attacker's own effect from its art, when it has one.
  AttackEffect? _fxArt;

  int _lastItemNonce = 0;
  String? _itemUser;
  String? _itemTarget;
  int _lastHealNonce = 0;
  String? _healer;
  String? _healTarget;
  final Map<String, int> _prevHp = {};
  final List<_Popup> _popups = [];
  int _popupSerial = 0;

  @override
  void initState() {
    super.initState();
    _controller = BattleController(
      playerPicks: widget.playerPicks,
      enemyPicks: widget.enemyPicks,
    )..addListener(_onChanged);
    _snapshotHp();
  }

  void _snapshotHp() {
    for (final c in [..._controller.player, ..._controller.enemy]) {
      _prevHp[c.id] = c.hp;
    }
  }

  void _onChanged() {
    final c = _controller;
    if (c.attackNonce != _lastNonce) {
      _lastNonce = c.attackNonce;
      _fxAttacker = c.lastAttackerId;
      _fxTarget = c.lastTargetId;
      _fxColor = c.lastAttackerElement?.color ?? Colors.white;
      _fxElement = c.lastAttackerElement;
      _fxDefended = c.lastTargetDefended;
      final attacker = [
        ...c.player,
        ...c.enemy,
      ].where((x) => x.id == c.lastAttackerId).firstOrNull;
      _fxArt = attacker == null ? null : attackEffects[attacker.name];
      final target = [
        ...c.player,
        ...c.enemy,
      ].where((x) => x.id == c.lastTargetId).firstOrNull;
      _fxKill = target != null && !target.alive;
      _fxBig =
          _fxKill || c.lastHitCrit || c.lastMatchup == ElementMatchup.advantage;
      _act.duration = _fxKill ? _knockoutHit : _normalHit;
      _act.forward(from: 0);
    }
    if (c.itemNonce != _lastItemNonce) {
      _lastItemNonce = c.itemNonce;
      _itemUser = c.lastItemUserId;
      _itemTarget = c.lastItemTargetId;
      final (label, color) = switch (c.lastItemType) {
        ItemType.boost => ('ATK UP', BattleColors.gold),
        ItemType.defend => ('DEF UP', const Color(0xFF85D9E4)),
        ItemType.weaken => ('WEAKENED', BattleColors.hpRed),
        null => ('', BattleColors.cream),
      };
      if (_itemTarget != null && label.isNotEmpty) {
        _addPopup(_itemTarget!, label, color, color, delay: 450);
      }
      _item.forward(from: 0);
    }
    if (c.healNonce != _lastHealNonce) {
      _lastHealNonce = c.healNonce;
      _healer = c.lastHealerId;
      _healTarget = c.lastHealTargetId;
      _heal.forward(from: 0);
    }
    for (final champ in [...c.player, ...c.enemy]) {
      final before = _prevHp[champ.id];
      if (before != null && before != champ.hp) {
        final diff = champ.hp - before;
        // Damage lands mid-swing, so its number waits for the hit; heals
        // have no swing and show straight away.
        _addPopup(
          champ.id,
          diff < 0 ? '${-diff}' : '+$diff',
          diff < 0 ? BattleColors.cream : BattleColors.hpGreen,
          diff < 0 ? _fxColor : BattleColors.hpGreen,
          // Matches the hit landing, which is later in slow motion.
          delay: diff < 0
              ? (380 * _act.duration!.inMilliseconds / 900).round()
              : 0,
        );
      }
      _prevHp[champ.id] = champ.hp;
    }
    final actor = c.currentActor;
    if (actor == null || actor.side != Side.player || c.winner != null) {
      _mode = _MenuMode.main;
    }
    setState(() {});
  }

  void _addPopup(
    String champId,
    String text,
    Color color,
    Color glow, {
    int delay = 0,
  }) {
    final popup = _Popup(_popupSerial++, champId, text, color, glow);
    Future.delayed(Duration(milliseconds: delay), () {
      if (!mounted) return;
      setState(() => _popups.add(popup));
      Future.delayed(const Duration(milliseconds: 1100), () {
        if (mounted) setState(() => _popups.remove(popup));
      });
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _act.dispose();
    _idle.dispose();
    _item.dispose();
    _heal.dispose();
    super.dispose();
  }

  bool get _playerTurn {
    final a = _controller.currentActor;
    return a != null &&
        a.side == Side.player &&
        _controller.winner == null &&
        _controller.clashQueue.isEmpty;
  }

  bool _isTargetable(Champion c) {
    if (!_playerTurn || !c.alive) return false;
    return switch (_mode) {
      _MenuMode.attackTarget => c.side == Side.enemy,
      _MenuMode.itemTarget => true,
      _ => false,
    };
  }

  void _onSpriteTap(Champion c) {
    if (!_isTargetable(c)) return;
    _controller.handleTargetClick(c);
    setState(() => _mode = _MenuMode.main);
  }

  /// Names and headings: Cinzel, inherited from the app theme.
  TextStyle _heading(
    double size, {
    Color color = BattleColors.cream,
    double letterSpacing = 0.5,
  }) => TextStyle(
    fontSize: size,
    color: color,
    fontWeight: FontWeight.w600,
    letterSpacing: letterSpacing,
  );

  @override
  Widget build(BuildContext context) {
    final clash = _controller.currentClash;
    return Scaffold(
      backgroundColor: BattleColors.bgBottom,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            child: Column(
              children: [
                _messageBar(),
                Expanded(child: _battlefield()),
                _actionBar(),
                _bottomPanel(),
              ],
            ),
          ),
          if (_controller.winner != null) _resultOverlay(),
          if (clash != null)
            Positioned.fill(
              child: SpeedClashOverlay(
                key: ValueKey(_controller.clashSerial),
                clash: clash,
                onDone: _controller.dismissClash,
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- windows

  /// A dark panel trimmed in gold with a small diamond at each corner, the
  /// same ornament as [OrnateDivider]. [title] adds a small gold heading.
  Widget _window({
    required Widget child,
    String? title,
    EdgeInsets padding = const EdgeInsets.fromLTRB(12, 10, 12, 10),
  }) {
    final body = title == null
        ? child
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title.toUpperCase(),
                      style: _heading(
                        10,
                        color: BattleColors.gold,
                        letterSpacing: 2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            BattleColors.gold.withAlpha(0x99),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(child: child),
            ],
          );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  BattleColors.panel.withAlpha(0xF2),
                  BattleColors.bgMid.withAlpha(0xF2),
                ],
              ),
              border: Border.all(
                color: BattleColors.gold.withAlpha(0xAA),
                width: 1.2,
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 12),
              ],
            ),
          ),
        ),
        Padding(padding: padding, child: body),
        for (final a in const [
          Alignment.topLeft,
          Alignment.topRight,
          Alignment.bottomLeft,
          Alignment.bottomRight,
        ])
          Positioned.fill(
            child: Align(
              alignment: a,
              child: Transform.translate(
                offset: Offset(a.x * 3, a.y * 3),
                child: const _Diamond(size: 6),
              ),
            ),
          ),
      ],
    );
  }

  Widget _messageBar() {
    String text;
    if (_controller.winner != null) {
      text = _controller.winner == Side.player
          ? 'The arena is yours.'
          : 'Your champions have fallen.';
    } else if (_mode == _MenuMode.attackTarget) {
      text = 'Choose an enemy to attack.';
    } else if (_mode == _MenuMode.itemTarget) {
      text = 'Choose a target for ${_controller.pendingItem?.name}.';
    } else {
      text = _controller.log.first;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back, color: BattleColors.muted),
            tooltip: 'Back to menu',
          ),
          Expanded(
            // Tapping the message opens the full battle history.
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openHistory,
              child: SizedBox(
                height: 52,
                child: _window(
                  padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          text,
                          textAlign: TextAlign.center,
                          style: bodyStyle(fontSize: 15, height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Tooltip(
                        message: 'Battle history',
                        child: Icon(
                          Icons.history_edu,
                          size: 20,
                          color: BattleColors.gold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Slides up a scrollable list of everything that has happened this
  /// battle, newest first. It listens to the controller, so it keeps
  /// updating while open (enemy turns still play underneath).
  void _openHistory() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scroll) => Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [BattleColors.panel, BattleColors.bgMid],
            ),
            border: Border(
              top: BorderSide(color: BattleColors.gold.withAlpha(0xAA)),
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final log = _controller.log;
              return ListView.builder(
                controller: scroll,
                // Extra bottom room so the last lines scroll clear of the volume control.
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 88),
                itemCount: log.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) return _historyHeader();
                  return _historyLine(log[i - 1], newest: i == 1);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _historyHeader() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: BattleColors.dim,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 14),
        Text('Battle History', style: _heading(20, color: BattleColors.gold)),
        const SizedBox(height: 8),
        const OrnateDivider(),
        const SizedBox(height: 4),
        Text(
          'Newest first',
          style: bodyStyle(fontSize: 12, color: BattleColors.muted),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _historyLine(String line, {required bool newest}) {
    // Round breaks read as section dividers rather than log lines.
    if (line.startsWith('—')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: BattleColors.gold.withAlpha(0x55),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                line.replaceAll('—', '').trim().toUpperCase(),
                style: _heading(10, color: BattleColors.gold, letterSpacing: 2),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: BattleColors.gold.withAlpha(0x55),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 10),
            child: _Diamond(size: 5),
          ),
          Expanded(
            child: Text(
              line,
              style: bodyStyle(
                fontSize: 15,
                height: 1.3,
                color: newest ? BattleColors.cream : BattleColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ battlefield

  Widget _battlefield() {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        final scale = min(
          h / (spriteSize * 2.0),
          w / (spriteSize * 5.0),
        ).clamp(1.5, 7.0).floorToDouble();
        final sprite = spriteSize * scale;
        return AnimatedBuilder(
          animation: Listenable.merge([_act, _idle, _item, _heal]),
          builder: (context, _) {
            // Where each fighter's body is, for effects that travel
            // between them.
            final centers = <String, Offset>{};
            final children = <Widget>[
              Positioned.fill(
                child: Image.asset(
                  _backdrop,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                  filterQuality: FilterQuality.none,
                  errorBuilder: (_, _, _) =>
                      CustomPaint(painter: _BackdropPainter()),
                ),
              ),
              // Darkens the ground a little so the fighters stand out
              // against the busy art.
              const Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x00000000),
                          Color(0x33000000),
                          Color(0x66000000),
                        ],
                        stops: [0.25, 0.5, 1],
                      ),
                    ),
                  ),
                ),
              ),
            ];
            for (var i = 0; i < _controller.enemy.length; i++) {
              final c = _controller.enemy[i];
              final pos = _slot(i, w, h, sprite, left: true);
              centers[c.id] = pos + Offset(sprite / 2, sprite * 0.55);
              children.add(_fighter(c, pos, scale, sprite, enemy: true));
            }
            for (var i = 0; i < _controller.player.length; i++) {
              final c = _controller.player[i];
              final pos = _slot(i, w, h, sprite, left: false);
              centers[c.id] = pos + Offset(sprite / 2, sprite * 0.55);
              children.add(_fighter(c, pos, scale, sprite, enemy: false));
            }
            children.add(
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _BattleFxPainter(
                      attack: _act.isAnimating ? _act.value : null,
                      from: centers[_fxAttacker],
                      to: centers[_fxTarget],
                      element: _fxElement,
                      big: _fxBig,
                      kill: _fxKill,
                      item: _item.isAnimating ? _item.value : null,
                      itemFrom: centers[_itemUser],
                      itemTo: centers[_itemTarget],
                      pixel: max(2.0, scale * 1.2),
                      artProjectile: _fxArt != null,
                    ),
                  ),
                ),
              ),
            );
            final art = _attackArt(centers, sprite);
            if (art != null) children.add(art);
            return Transform.translate(
              offset: _shake(scale),
              child: Stack(clipBehavior: Clip.none, children: children),
            );
          },
        );
      },
    );
  }

  /// The attacker's own effect from its pixel art. A beam shoots out from
  /// the attacker and reaches the target as the hit lands, then fades; a
  /// ground effect bursts up under the target as the hit lands.
  Widget? _attackArt(Map<String, Offset> centers, double sprite) {
    final fx = _fxArt;
    final a = centers[_fxAttacker];
    final b = centers[_fxTarget];
    if (fx == null || a == null || b == null || !_act.isAnimating) {
      return null;
    }
    final t = _act.value;
    const launch = 0.12, land = 0.32, fadeEnd = 0.68;
    if (t < launch || t > fadeEnd) return null;
    final fade = t <= land + 0.1
        ? 1.0
        : 1 - (t - land - 0.1) / (fadeEnd - land - 0.1);
    final aspect = fx.height / fx.width;

    if (fx.ground) {
      if (t < land - 0.04) return null;
      final grow = ((t - land + 0.04) / 0.12).clamp(0.0, 1.0);
      final w = sprite * 1.5;
      final h = w * aspect;
      // Feet of the target: its center sits at 55% of the sprite.
      final feet = b + Offset(0, sprite * 0.45);
      return Positioned(
        left: feet.dx - w / 2,
        top: feet.dy - h,
        width: w,
        height: h,
        child: IgnorePointer(
          child: Opacity(
            opacity: fade.clamp(0.0, 1.0),
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.diagonal3Values(
                b.dx < a.dx ? -1.0 : 1.0,
                grow,
                1,
              ),
              child: Image.asset(
                fx.asset,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.none,
              ),
            ),
          ),
        ),
      );
    }

    // Start just in front of the attacker, end just past the target.
    final d = b - a;
    final dir = d / d.distance;
    final start = a + dir * sprite * 0.3;
    final end = b + dir * sprite * 0.25;
    final len = (end - start).distance;
    final h = min(len * aspect, sprite * 0.9);
    final reveal = ((t - launch) / (land - launch)).clamp(0.0, 1.0);
    final angle = atan2(d.dy, d.dx);
    // Flying left would turn the art upside down, so mirror it back.
    final transform = Matrix4.rotationZ(angle);
    if (d.dx < 0) transform.multiply(Matrix4.diagonal3Values(1, -1, 1));
    return Positioned(
      left: start.dx,
      top: start.dy - h / 2,
      width: len,
      height: h,
      child: IgnorePointer(
        child: Transform(
          alignment: Alignment.centerLeft,
          transform: transform,
          child: Opacity(
            opacity: fade.clamp(0.0, 1.0),
            child: ClipRect(
              clipper: _RevealClipper(reveal),
              child: Image.asset(
                fx.asset,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.none,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Big hits rattle the whole battlefield for a moment as they land.
  Offset _shake(double scale) {
    if (!_fxBig || !_act.isAnimating) return Offset.zero;
    final t = _act.value;
    if (t < 0.32 || t > 0.62) return Offset.zero;
    final k = (t - 0.32) / 0.3;
    final amp = scale * (_fxKill ? 3.5 : 2.5) * (1 - k);
    return Offset(sin(k * 42) * amp, cos(k * 31) * amp * 0.6);
  }

  /// Staggered column positions: the middle fighter of each side stands a
  /// step further back than the other two.
  Offset _slot(int i, double w, double h, double sprite, {required bool left}) {
    // Everyone stands on the ground, between the horizon and the bottom.
    final top = h * 0.30;
    final bottom = h - sprite - 8;
    final rowGap = max(0.0, bottom - top) / 2;
    final y = top + i * rowGap;
    final stagger = i == 1 ? sprite * 0.45 : 0.0;
    final x = left ? w * 0.08 + stagger : w * 0.92 - sprite - stagger;
    return Offset(x, y);
  }

  Widget _fighter(
    Champion c,
    Offset pos,
    double scale,
    double sprite, {
    required bool enemy,
  }) {
    final t = _act.value;
    final animating = _act.isAnimating;
    var dx = 0.0;
    var flash = 0.0;
    var flashColor = Colors.white;

    // The champion whose turn it is steps forward.
    final isActor =
        _controller.currentActor?.id == c.id && _controller.winner == null;
    if (isActor && !animating) dx += enemy ? sprite * 0.25 : -sprite * 0.25;
    // Gold marks your champion's turn, red an enemy's.
    final turnColor = enemy ? BattleColors.hpRed : BattleColors.gold;

    if (animating && c.id == _fxAttacker) {
      // Lunge toward the other side and back.
      final lunge = t < 0.35 ? t / 0.35 : (t < 0.6 ? 1.0 : 1 - (t - 0.6) / 0.4);
      dx += (enemy ? 1 : -1) * sprite * 0.6 * lunge.clamp(0, 1);
      if (t < 0.25) {
        flash = 0.6 * (1 - t / 0.25);
        flashColor = _fxColor;
      }
    }
    if (animating && c.id == _fxTarget && t > 0.32) {
      final k = ((t - 0.32) / 0.5).clamp(0.0, 1.0);
      // A blocked hit barely pushes the target back.
      final push = _fxDefended ? 0.4 : 1.0;
      dx += sin(k * pi * 6) * scale * 2 * (1 - k) * push;
      flash = (1 - k) * (_fxDefended ? 0.4 : 0.9);
      flashColor = k < 0.3 ? Colors.white : _fxColor;
    }
    // The item's target glows gold as the magic reaches them.
    final itemT = _item.value;
    if (_item.isAnimating && c.id == _itemTarget && itemT > 0.45) {
      flash = max(flash, 0.5 * (1 - (itemT - 0.45) / 0.55));
      flashColor = BattleColors.gold;
    }
    // The heal's target glows green as the healing lands.
    final healT = _heal.value;
    if (_heal.isAnimating && c.id == _healTarget && healT > 0.5) {
      flash = max(flash, 0.5 * (1 - (healT - 0.5) / 0.5));
      flashColor = BattleColors.hpGreen;
    }

    // Which animation an animated sprite sheet plays, and how far along.
    // The hit lands at about a third of the way through the attack.
    final hitProgress = ((t - 0.32) / 0.6).clamp(0.0, 1.0);
    var pose = SpritePose.idle;
    var poseProgress = _idle.value;
    if (!c.alive) {
      pose = SpritePose.death;
      poseProgress = animating && c.id == _fxTarget ? hitProgress : 1.0;
    } else if (animating && c.id == _fxAttacker) {
      pose = SpritePose.attack;
      poseProgress = t;
    } else if (animating && c.id == _fxTarget && t > 0.32) {
      pose = _fxDefended ? SpritePose.defend : SpritePose.hurt;
      poseProgress = hitProgress;
    } else if (_heal.isAnimating && c.id == _healer) {
      pose = SpritePose.heal;
      poseProgress = _heal.value;
    } else if (_item.isAnimating && c.id == _itemUser) {
      pose = SpritePose.item;
      poseProgress = _item.value;
    } else if (_controller.winner == c.side) {
      // The winning side celebrates for as long as the result is shown.
      pose = SpritePose.victory;
      poseProgress = _idle.value;
    }

    final targetable = _isTargetable(c);
    final popups = _popups.where((p) => p.champId == c.id).toList();

    return Positioned(
      left: pos.dx + dx,
      top: pos.dy,
      width: sprite,
      height: sprite,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onSpriteTap(c),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Shadow under the feet.
            Positioned(
              left: sprite * 0.25,
              right: sprite * 0.25,
              bottom: -scale,
              height: scale * 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(0x66),
                  borderRadius: BorderRadius.circular(sprite),
                ),
              ),
            ),
            // Glowing ring under whoever's turn it is.
            if (isActor)
              Positioned(
                left: sprite * 0.1,
                right: sprite * 0.1,
                bottom: -scale * 2.5,
                height: scale * 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(sprite),
                    border: Border.all(
                      color: turnColor.withAlpha(0xCC),
                      width: 1.5,
                    ),
                    gradient: RadialGradient(
                      colors: [
                        turnColor.withAlpha(0x88),
                        turnColor.withAlpha(0x00),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: turnColor.withAlpha(0x66),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
            BattleSpriteView(
              championName: c.name,
              boxSize: sprite,
              flipX: !enemy,
              flash: flash,
              flashColor: flashColor,
              knockedOut: !c.alive,
              pose: pose,
              poseProgress: poseProgress,
            ),
            // Enemy HP floats just above the head (the sprites leave a few
            // empty rows at the top). Your team's HP is in the window below.
            if (enemy && c.alive)
              Positioned(
                top: -scale * 3 - 14,
                left: sprite * 0.1,
                right: sprite * 0.1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${c.hp} / ${c.maxHp}',
                      style:
                          bodyStyle(
                            fontSize: 12,
                            height: 1,
                            color: c.hp <= c.maxHp / 4
                                ? BattleColors.hpRed
                                : BattleColors.cream,
                          ).copyWith(
                            shadows: const [
                              Shadow(color: Colors.black, blurRadius: 3),
                            ],
                          ),
                    ),
                    const SizedBox(height: 2),
                    _HpBar(fraction: c.hp / c.maxHp),
                  ],
                ),
              ),
            // Bouncing arrow over whoever's turn it is, above the enemy HP
            // and target marker so nothing overlaps.
            if (isActor)
              Positioned(
                top:
                    -scale * 3 -
                    (enemy ? 44 : 26) +
                    sin(_idle.value * 2 * pi) * 3,
                left: 0,
                right: 0,
                child: Center(child: _TurnMarker(color: turnColor)),
              ),
            if (targetable)
              Positioned(
                top: enemy ? -scale * 3 - 34 : -scale * 3,
                left: 0,
                right: 0,
                child: const Center(child: _Diamond(size: 12, glow: true)),
              ),
            for (final p in popups)
              Positioned(
                key: ValueKey(p.key),
                left: -40,
                right: -40,
                top: sprite * 0.1,
                child: _DamageNumber(
                  text: p.text,
                  color: p.color,
                  glow: p.glow,
                  size: max(22, scale * 5),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------- bottom panel

  Widget _bottomPanel() {
    return Padding(
      // Leaves room for the global volume control in the bottom-left corner.
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 60),
      // Enemy names already show on the target buttons and the field, so
      // the party gets the full width to stay readable on a phone.
      child: SizedBox(height: 136, child: _partyWindow()),
    );
  }

  Widget _nameRow(Champion c, {Color? color, Widget? trailing}) {
    final dead = !c.alive;
    return Row(
      children: [
        Icon(
          c.element.icon,
          size: 13,
          color: dead ? BattleColors.faint : c.element.color,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            c.name,
            style: _heading(
              13,
              color: dead ? BattleColors.faint : (color ?? BattleColors.cream),
            ).copyWith(decoration: dead ? TextDecoration.lineThrough : null),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ?trailing,
      ],
    );
  }

  // ------------------------------------------------------------- action bar

  /// Full-width row of large, thumb-sized buttons under the battlefield.
  /// It keeps the same height on every turn so the layout never jumps; on
  /// the enemy's turn it just says who is acting.
  Widget _actionBar() {
    final actor = _controller.currentActor;
    final String heading;
    final List<Widget> buttons;

    if (!_playerTurn || actor == null) {
      heading = '';
      final text = _controller.winner != null
          ? ''
          : (actor == null ? '' : '${actor.name} is acting...');
      buttons = [
        Expanded(
          child: Center(
            child: Text(
              text,
              style: bodyStyle(fontSize: 15, color: BattleColors.muted),
            ),
          ),
        ),
      ];
    } else {
      switch (_mode) {
        case _MenuMode.main:
          heading = "${actor.name}'s turn";
          buttons = [
            _bigButton(
              label: 'Attack',
              primary: true,
              onTap: () => setState(() => _mode = _MenuMode.attackTarget),
            ),
            if (actor.role == ChampionRole.healer)
              _bigButton(
                label: 'Heal',
                onTap: () => setState(() => _mode = _MenuMode.attackTarget),
              ),
            _bigButton(
              label: 'Item',
              onTap: () => setState(() => _mode = _MenuMode.items),
            ),
          ];
        case _MenuMode.attackTarget:
          heading = 'Attack who?';
          buttons = [
            for (final e in _controller.enemy.where((e) => e.alive))
              _bigButton(
                label: e.name,
                icon: e.element.icon,
                iconColor: e.element.color,
                // HP shows over each enemy's head, so the button keeps just
                // the element hint, which fits on a phone.
                sub: _matchTag(actor.element.matchupAgainst(e.element)),
                subColor: _matchColor(actor.element.matchupAgainst(e.element)),
                onTap: () => _onSpriteTap(e),
              ),
            _cancelButton(() => setState(() => _mode = _MenuMode.main)),
          ];
        case _MenuMode.items:
          heading = 'Use which item?';
          buttons = [
            for (final item in _controller.hand)
              _bigButton(
                label: item.name,
                sub: item.desc,
                onTap: () => _pickItem(item),
              ),
            _cancelButton(() => setState(() => _mode = _MenuMode.main)),
          ];
        case _MenuMode.itemTarget:
          heading = _controller.pendingItem?.name ?? 'Item';
          buttons = [
            Expanded(
              child: Center(
                child: Text(
                  'Tap a champion on the field.',
                  style: bodyStyle(fontSize: 15, color: BattleColors.muted),
                ),
              ),
            ),
            _cancelButton(() {
              final pending = _controller.pendingItem;
              if (pending != null) _controller.togglePendingItem(pending);
              setState(() => _mode = _MenuMode.main);
            }),
          ];
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 18,
            child: Text(
              heading.toUpperCase(),
              style: _heading(11, color: BattleColors.gold, letterSpacing: 2),
            ),
          ),
          SizedBox(
            height: 72,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < buttons.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  buttons[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A big tappable button: the main gold one (Attack) is filled, the rest
  /// are dark panels trimmed in gold, matching the menu screen's buttons.
  Widget _bigButton({
    required String label,
    required VoidCallback onTap,
    bool primary = false,
    String? sub,
    Color? subColor,
    IconData? icon,
    Color? iconColor,
  }) {
    final textColor = primary ? const Color(0xFF14121A) : BattleColors.cream;
    final compact = sub != null || icon != null;
    return Expanded(
      child: Material(
        color: primary ? BattleColors.gold : BattleColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: primary
                ? BattleColors.gold
                : BattleColors.gold.withAlpha(0x99),
            width: 1.2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: BattleColors.gold.withAlpha(0x44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Long names (targets, items) wrap onto two lines in a
                // smaller size rather than being cut off on a phone.
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: _heading(
                    compact ? 13 : 16,
                    color: textColor,
                  ).copyWith(height: 1.05),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sub != null || icon != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null)
                          Icon(icon, size: 12, color: iconColor),
                        if (icon != null && sub != null)
                          const SizedBox(width: 4),
                        if (sub != null)
                          Flexible(
                            child: Text(
                              sub,
                              textAlign: TextAlign.center,
                              style: bodyStyle(
                                fontSize: 12,
                                color: subColor ?? BattleColors.muted,
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cancelButton(VoidCallback onTap) {
    return SizedBox(
      width: 56,
      child: Material(
        color: BattleColors.bgMid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: BattleColors.muted),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const Tooltip(
            message: 'Back',
            child: Icon(Icons.close, color: BattleColors.cream),
          ),
        ),
      ),
    );
  }

  void _pickItem(GameItem item) {
    if (!identical(_controller.pendingItem, item)) {
      _controller.togglePendingItem(item);
    }
    setState(() => _mode = _MenuMode.itemTarget);
  }

  String? _matchTag(ElementMatchup m) => switch (m) {
    ElementMatchup.advantage => 'Strong',
    ElementMatchup.disadvantage => 'Weak',
    ElementMatchup.neutral => null,
  };

  Color _matchColor(ElementMatchup m) =>
      m == ElementMatchup.advantage ? BattleColors.hpGreen : BattleColors.hpRed;

  Widget _partyWindow() {
    final actorId = _controller.winner == null
        ? _controller.currentActor?.id
        : null;
    return _window(
      title: 'Your Team',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final p in _controller.player)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _nameRow(
                  p,
                  color: actorId == p.id ? BattleColors.gold : null,
                  trailing: Text(
                    '${p.hp} / ${p.maxHp}',
                    style: bodyStyle(
                      fontSize: 14,
                      color: !p.alive
                          ? BattleColors.faint
                          : (p.hp <= p.maxHp / 4
                                ? BattleColors.hpRed
                                : BattleColors.cream),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                _HpBar(fraction: p.maxHp == 0 ? 0 : p.hp / p.maxHp),
              ],
            ),
        ],
      ),
    );
  }

  Widget _resultOverlay() {
    final won = _controller.winner == Side.player;
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: SizedBox(
        width: 320,
        height: 190,
        child: _window(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                won ? 'Victory.' : 'Defeat.',
                style: _heading(28, color: BattleColors.gold),
              ),
              const SizedBox(height: 10),
              const OrnateDivider(),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BattleColors.cream,
                      side: const BorderSide(color: BattleColors.muted),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text('Menu'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _controller.resetBattle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BattleColors.gold,
                      foregroundColor: const Color(0xFF14121A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text('Fight Again'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A downward arrow with a glow, floating over the champion whose turn it
/// is.
class _TurnMarker extends StatelessWidget {
  const _TurnMarker({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(18, 14),
      painter: _TurnMarkerPainter(color),
    );
  }
}

class _TurnMarkerPainter extends CustomPainter {
  _TurnMarkerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final arrow = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(
      arrow,
      Paint()
        ..color = color.withAlpha(0x99)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(arrow, Paint()..color = color);
    canvas.drawPath(
      arrow,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_TurnMarkerPainter old) => old.color != color;
}

/// The small gold diamond used throughout the game's ornaments, here as
/// menu bullets, window corners and the target marker over a fighter.
class _Diamond extends StatelessWidget {
  const _Diamond({required this.size, this.glow = false});

  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: pi / 4,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: BattleColors.gold,
          border: glow
              ? Border.all(color: const Color(0xFFFFF1C2), width: 1.5)
              : null,
          boxShadow: glow
              ? [
                  BoxShadow(
                    color: BattleColors.gold.withAlpha(0xAA),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

/// A thin HP bar in the card battle's green/red.
class _HpBar extends StatelessWidget {
  const _HpBar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final f = fraction.clamp(0.0, 1.0);
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: BattleColors.logBorder,
        borderRadius: BorderRadius.circular(2),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: f,
        child: Container(
          decoration: BoxDecoration(
            color: f <= 0.25 ? BattleColors.hpRed : BattleColors.hpGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

/// A damage or heal number that hops up and fades, set in Cinzel with a
/// dark outline and a glow in the color of whatever caused it.
class _DamageNumber extends StatelessWidget {
  const _DamageNumber({
    required this.text,
    required this.color,
    required this.glow,
    required this.size,
  });

  final String text;
  final Color color;
  final Color glow;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color,
      shadows: [
        for (final o in const [
          Offset(1.5, 1.5),
          Offset(-1.5, 1.5),
          Offset(1.5, -1.5),
          Offset(-1.5, -1.5),
        ])
          Shadow(color: Colors.black, offset: o),
        Shadow(color: glow, blurRadius: 12),
      ],
    );
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      builder: (context, t, _) {
        final hop = t < 0.3 ? -sin(t / 0.3 * pi) * 18 : 0.0;
        final opacity = t < 0.75 ? 1.0 : 1 - (t - 0.75) / 0.25;
        return Opacity(
          opacity: opacity.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, hop - t * 10),
            child: Center(child: Text(text, style: style)),
          ),
        );
      },
    );
  }
}

/// Effects that travel across the battlefield, drawn in chunky pixels to
/// match the sprites: each element's projectile flying from attacker to
/// target, a burst of particles where it lands (bigger for big hits, with a
/// white shockwave on a knockout), and a stream of sparkles for item use.
/// [attack] and [item] are each animation's progress, or null when idle.
class _BattleFxPainter extends CustomPainter {
  _BattleFxPainter({
    required this.attack,
    required this.from,
    required this.to,
    required this.element,
    required this.big,
    required this.kill,
    required this.item,
    required this.itemFrom,
    required this.itemTo,
    required this.pixel,
    this.artProjectile = false,
  });

  /// The attacker's art draws its own projectile, so skip the generic one.
  final bool artProjectile;

  final double? attack;
  final Offset? from;
  final Offset? to;
  final GameElement? element;
  final bool big;
  final bool kill;
  final double? item;
  final Offset? itemFrom;
  final Offset? itemTo;
  final double pixel;

  /// The hit lands here (fraction of the attack animation); projectiles
  /// launch a little before it.
  static const _launch = 0.1;
  static const _land = 0.32;

  void _block(Canvas canvas, Offset c, Color color, [double size = 1]) {
    final s = pixel * size;
    canvas.drawRect(
      Rect.fromCenter(center: c, width: s, height: s),
      Paint()
        ..color = color
        ..isAntiAlias = false,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = attack;
    final a = from;
    final b = to;
    final el = element;
    if (t != null && a != null && b != null && el != null) {
      if (!artProjectile && t >= _launch && t <= _land) {
        _projectile(canvas, a, b, (t - _launch) / (_land - _launch), el);
      }
      if (t > _land) _impact(canvas, b, (t - _land) / (1 - _land), el);
    }
    final it = item;
    final ia = itemFrom;
    final ib = itemTo;
    if (it != null && ia != null && ib != null) {
      _itemSparkles(canvas, ia, ib, it);
    }
  }

  void _projectile(
    Canvas canvas,
    Offset a,
    Offset b,
    double p,
    GameElement el,
  ) {
    final pos = Offset.lerp(a, b, p)!;
    final dir = (b - a).dx.sign; // +1 when flying right
    switch (el) {
      case GameElement.water:
        // A wave that swells as it rolls toward the target.
        final rows = 2 + (p * 3).floor();
        for (var r = 0; r < rows; r++) {
          final width = 3 + r * 2;
          for (var i = 0; i < width; i++) {
            final x = pos.dx - dir * (i * pixel * 0.9);
            final y =
                pos.dy + (r - rows) * pixel + sin(i * 0.9 + p * 9) * pixel;
            _block(
              canvas,
              Offset(x, y),
              r == 0 ? const Color(0xFFD7FBFF) : const Color(0xFF3AA8D4),
            );
          }
        }
        for (var i = 0; i < 4; i++) {
          _block(
            canvas,
            pos + Offset(-dir * pixel * (6 + i * 2), -pixel * (3 + i % 2 * 2)),
            const Color(0xFF85D9E4),
            0.7,
          );
        }
      case GameElement.fire:
        // A fireball trailing embers.
        for (var i = 0; i < 6; i++) {
          final back =
              pos -
              Offset(dir * pixel * 1.6 * i, sin(p * 20 + i) * pixel * 0.6);
          _block(
            canvas,
            back,
            i == 0
                ? const Color(0xFFFFF3A1)
                : (i < 3 ? const Color(0xFFFFD23F) : const Color(0xFFFF7A1A)),
            i == 0 ? 2.4 : 2.0 - i * 0.25,
          );
        }
        _block(canvas, pos, const Color(0xFFFF7A1A), 3.2);
        _block(canvas, pos, const Color(0xFFFFD23F), 2.2);
        _block(canvas, pos, const Color(0xFFFFF3C4), 1.1);
      case GameElement.lightning:
        // A jagged bolt that strikes the whole way at once and flickers.
        if ((p * 10).floor().isEven || p > 0.6) {
          final path = Path()..moveTo(a.dx, a.dy);
          const segments = 7;
          for (var i = 1; i < segments; i++) {
            final q = Offset.lerp(a, b, i / segments)!;
            path.lineTo(q.dx, q.dy + (i.isEven ? -1 : 1) * pixel * 3);
          }
          path.lineTo(b.dx, b.dy);
          canvas.drawPath(
            path,
            Paint()
              ..color = const Color(0xFFFFD23F)
              ..style = PaintingStyle.stroke
              ..strokeWidth = pixel * 1.6
              ..strokeJoin = StrokeJoin.miter,
          );
          canvas.drawPath(
            path,
            Paint()
              ..color = const Color(0xFFFFFBE0)
              ..style = PaintingStyle.stroke
              ..strokeWidth = pixel * 0.6,
          );
        }
      case GameElement.earth:
        // Rocks hurled in an arc.
        for (var i = 0; i < 3; i++) {
          final q = (p - i * 0.12).clamp(0.0, 1.0);
          final rock =
              Offset.lerp(a, b, q)! +
              Offset(0, -sin(q * pi) * pixel * 14 + i * pixel * 2);
          _block(canvas, rock, const Color(0xFF4A3A22), 2.6);
          _block(
            canvas,
            rock + Offset(-pixel * 0.4, -pixel * 0.4),
            const Color(0xFF8A6A3A),
            1.4,
          );
        }
      case GameElement.wind:
        // Pale crescents of wind.
        for (var i = 0; i < 3; i++) {
          final q = (p - i * 0.1).clamp(0.0, 1.0);
          final c = Offset.lerp(a, b, q)! + Offset(0, (i - 1) * pixel * 3);
          for (var j = -2; j <= 2; j++) {
            _block(
              canvas,
              c + Offset(-dir * (j * j) * pixel * 0.5, j * pixel),
              j == 0 ? const Color(0xFFFFFFFF) : const Color(0xFFCFE3F0),
            );
          }
        }
    }
  }

  void _impact(Canvas canvas, Offset at, double k, GameElement el) {
    if (k >= 1) return;
    final count = big ? 22 : 12;
    final reach = pixel * (big ? 16 : 10);
    final colors = switch (el) {
      GameElement.water => const [Color(0xFF3AA8D4), Color(0xFFD7FBFF)],
      GameElement.fire => const [Color(0xFFFF7A1A), Color(0xFFFFD23F)],
      GameElement.lightning => const [Color(0xFFFFD23F), Color(0xFFFFFBE0)],
      GameElement.earth => const [Color(0xFF6B4A2A), Color(0xFFB08A50)],
      GameElement.wind => const [Color(0xFFCFE3F0), Color(0xFFFFFFFF)],
    };
    final fade = (1 - k).clamp(0.0, 1.0);
    for (var i = 0; i < count; i++) {
      final angle = i * 2 * pi / count + (i.isEven ? 0.2 : -0.15);
      final dist = reach * (0.35 + 0.65 * k) * (i % 3 == 0 ? 1.2 : 1.0);
      // Earth and water particles fall back down; the rest fly outward.
      final drop = (el == GameElement.earth || el == GameElement.water)
          ? k * k * pixel * 10
          : 0.0;
      final c = at + Offset(cos(angle) * dist, sin(angle) * dist + drop);
      _block(
        canvas,
        c,
        colors[i % 2].withValues(alpha: fade),
        (big ? 1.6 : 1.2) * (1 - k * 0.5),
      );
    }
    if (kill && k < 0.6) {
      // A white shockwave on a knockout.
      canvas.drawCircle(
        at,
        pixel * 4 + k * pixel * 30,
        Paint()
          ..color = Colors.white.withValues(alpha: (1 - k / 0.6) * 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = pixel * 1.2,
      );
    }
  }

  void _itemSparkles(Canvas canvas, Offset a, Offset b, double t) {
    const gold = Color(0xFFF3DDA0);
    const bright = Color(0xFFFFFBE0);
    if (t < 0.45) {
      // Sparkles gather around the user...
      final k = t / 0.45;
      for (var i = 0; i < 8; i++) {
        final angle = i * pi / 4 + k * 3;
        final r = pixel * (10 - k * 6);
        _block(
          canvas,
          a + Offset(cos(angle) * r, sin(angle) * r - k * pixel * 4),
          i.isEven ? gold : bright,
          1.1,
        );
      }
    } else if (a == b) {
      // ...then burst outward when the item is used on themselves...
      final k = (t - 0.45) / 0.55;
      for (var i = 0; i < 10; i++) {
        final angle = i * pi / 5;
        _block(
          canvas,
          a + Offset(cos(angle), sin(angle)) * pixel * (4 + k * 10),
          (i.isEven ? gold : bright).withValues(alpha: 1 - k),
          1.1,
        );
      }
    } else {
      // ...or fly to an ally (or enemy) and burst there.
      final k = (t - 0.45) / 0.55;
      final travel = (k / 0.5).clamp(0.0, 1.0);
      if (k < 0.5) {
        for (var i = 0; i < 5; i++) {
          final q = (travel - i * 0.06).clamp(0.0, 1.0);
          final p =
              Offset.lerp(a, b, q)! + Offset(0, -sin(q * pi) * pixel * 10);
          _block(canvas, p, i == 0 ? bright : gold, 1.3 - i * 0.15);
        }
      } else {
        final burst = (k - 0.5) / 0.5;
        for (var i = 0; i < 10; i++) {
          final angle = i * pi / 5;
          _block(
            canvas,
            b + Offset(cos(angle), sin(angle)) * pixel * (3 + burst * 10),
            (i.isEven ? gold : bright).withValues(alpha: 1 - burst),
            1.1,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_BattleFxPainter old) => true;
}

/// A simple pixel backdrop (dusk sky, distant mountains and a dirt field),
/// shown if the battlefield art can't load.
class _BackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1B1530), Color(0xFF4A2A44), Color(0xFF8A4A3A)],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.45));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.45), sky);

    final rng = Random(3);
    final stars = Paint()..color = Colors.white.withAlpha(0x88);
    for (var i = 0; i < 40; i++) {
      canvas.drawRect(
        Rect.fromLTWH(rng.nextDouble() * w, rng.nextDouble() * h * 0.25, 2, 2),
        stars,
      );
    }

    final step = max(4.0, (w / 120).floorToDouble());
    final far = Paint()..color = const Color(0xFF2A1E36);
    final near = Paint()..color = const Color(0xFF1E1628);
    for (var x = 0.0; x < w; x += step) {
      final m1 =
          h * 0.30 + sin(x / w * 9) * h * 0.06 + sin(x / w * 23) * h * 0.02;
      final m2 = h * 0.37 + sin(x / w * 6 + 1) * h * 0.04;
      canvas.drawRect(
        Rect.fromLTWH(x, (m1 / step).floor() * step, step, h * 0.45),
        far,
      );
      canvas.drawRect(
        Rect.fromLTWH(x, (m2 / step).floor() * step, step, h * 0.45),
        near,
      );
    }

    final ground = Rect.fromLTWH(0, h * 0.42, w, h * 0.58);
    canvas.drawRect(ground, Paint()..color = const Color(0xFF4A3A2C));
    final light = Paint()..color = const Color(0xFF5C4A38);
    final dark = Paint()..color = const Color(0xFF3A2C22);
    for (var i = 0; i < 160; i++) {
      final x = (rng.nextDouble() * w / step).floor() * step;
      final y = h * 0.44 + (rng.nextDouble() * h * 0.56 / step).floor() * step;
      canvas.drawRect(
        Rect.fromLTWH(x, y, step * 2, step),
        i.isEven ? light : dark,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.42, w, step),
      Paint()..color = const Color(0xFF6A5640),
    );
  }

  @override
  bool shouldRepaint(_BackdropPainter old) => false;
}

/// Shows the left [fraction] of its child, so a beam can shoot out.
class _RevealClipper extends CustomClipper<Rect> {
  _RevealClipper(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_RevealClipper old) => old.fraction != fraction;
}
