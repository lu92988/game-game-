import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

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
    this.playerNames = const ['Robotoman', 'Thunderboy', 'Krogg'],
    this.enemyNames = const ['Demon Knight', 'Friedrich Blitzberg', 'Riptide'],
  });

  final List<String> playerNames;
  final List<String> enemyNames;

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
  late final AnimationController _act = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  /// Loops forever to drive the idle row of animated sprite sheets.
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  _MenuMode _mode = _MenuMode.main;
  int _lastNonce = 0;
  String? _fxAttacker;
  String? _fxTarget;
  Color _fxColor = Colors.white;
  final Map<String, int> _prevHp = {};
  final List<_Popup> _popups = [];
  int _popupSerial = 0;

  static ChampionDef _def(String name) =>
      roster.firstWhere((d) => d.name == name);

  @override
  void initState() {
    super.initState();
    _controller = BattleController(
      playerPicks: widget.playerNames.map(_def).toList(),
      enemyPicks: widget.enemyNames.map(_def).toList(),
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
      _act.forward(from: 0);
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
          delay: diff < 0 ? 380 : 0,
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
        final children = <Widget>[
          Positioned.fill(child: CustomPaint(painter: _BackdropPainter())),
        ];
        for (var i = 0; i < _controller.enemy.length; i++) {
          final pos = _slot(i, w, h, sprite, left: true);
          children.add(
            _fighter(_controller.enemy[i], pos, scale, sprite, enemy: true),
          );
        }
        for (var i = 0; i < _controller.player.length; i++) {
          final pos = _slot(i, w, h, sprite, left: false);
          children.add(
            _fighter(_controller.player[i], pos, scale, sprite, enemy: false),
          );
        }
        return AnimatedBuilder(
          animation: Listenable.merge([_act, _idle]),
          builder: (context, _) =>
              Stack(clipBehavior: Clip.none, children: children),
        );
      },
    );
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
      dx += sin(k * pi * 6) * scale * 2 * (1 - k);
      flash = (1 - k) * 0.9;
      flashColor = k < 0.3 ? Colors.white : _fxColor;
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
      pose = SpritePose.hurt;
      poseProgress = hitProgress;
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

/// A simple pixel backdrop: dusk sky, distant mountains and a dirt field.
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
