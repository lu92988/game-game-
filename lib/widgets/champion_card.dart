import 'dart:math';

import 'package:flutter/material.dart';

import '../data/champion_art.dart';
import '../data/champion_attack_art.dart';
import '../models/champion.dart';
import '../models/game_element.dart';
import '../theme/battle_colors.dart';
import 'element_effect.dart';

class ChampionCard extends StatefulWidget {
  const ChampionCard({
    super.key,
    required this.champ,
    this.onTap,
    this.clickable = false,
    this.isCurrent = false,
    this.disabled = false,
    this.attackNonce = 0,
    this.attackerId,
    this.targetId,
    this.attackerElement,
  });

  final Champion champ;
  final VoidCallback? onTap;
  final bool clickable;
  final bool isCurrent;
  final bool disabled;

  /// Bumped by [BattleController] on every attack; [attackerId]/[targetId]
  /// say who was involved. Comparing nonces (not just the ids) is what lets
  /// this card replay its effect even when the same champion acts twice in
  /// a row.
  final int attackNonce;
  final String? attackerId;
  final String? targetId;

  /// The attacking champion's element — used to color the *target's*
  /// impact burst so a hit visibly carries the element that caused it.
  final GameElement? attackerElement;

  @override
  State<ChampionCard> createState() => _ChampionCardState();
}

class _ChampionCardState extends State<ChampionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fx;
  late int _lastHandledNonce;
  bool _isAttackGlow = false;

  @override
  void initState() {
    super.initState();
    _fx = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _lastHandledNonce = widget.attackNonce;
  }

  @override
  void didUpdateWidget(covariant ChampionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.attackNonce != _lastHandledNonce) {
      _lastHandledNonce = widget.attackNonce;
      if (widget.champ.id == widget.attackerId) {
        _isAttackGlow = true;
        _fx.forward(from: 0);
      } else if (widget.champ.id == widget.targetId) {
        _isAttackGlow = false;
        _fx.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _fx.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final champ = widget.champ;
    final el = champ.element;
    final hpPct = (champ.hp / champ.maxHp).clamp(0.0, 1.0);
    final isTargetable = widget.clickable && champ.alive;
    final art = artFor(champ.name);

    final Color borderColor = widget.isCurrent
        ? BattleColors.gold
        : champ.alive
        ? el.color.withAlpha(0x55)
        : BattleColors.logBorder;

    final double opacity = champ.alive
        ? (widget.disabled && !isTargetable && !widget.isCurrent ? 0.55 : 1)
        : 0.35;

    return AnimatedBuilder(
      animation: _fx,
      builder: (context, child) {
        final t = _fx.value;
        final fxActive = t < 1;

        List<BoxShadow>? glow;
        if (widget.isCurrent) {
          glow = [
            BoxShadow(
              color: BattleColors.gold.withAlpha(0xAA),
              spreadRadius: 2,
              blurRadius: 0,
            ),
          ];
        }
        if (fxActive && _isAttackGlow) {
          final fade = (1 - t);
          glow = [
            ...?glow,
            BoxShadow(
              color: el.color.withAlpha((0xDD * fade).round()),
              spreadRadius: 6,
              blurRadius: 16,
            ),
          ];
        }

        final isImpact = fxActive && !_isAttackGlow;
        final dx = isImpact ? sin(t * pi * 8) * 6 * (1 - t) : 0.0;
        // A quick punch-in right at the moment of impact, settled by t=0.25
        // — separate from the longer shake/burst so the "hit" itself still
        // reads as sharp even though the overall effect is drawn out.
        final scale = isImpact && t < 0.25
            ? 1.0 + sin((t / 0.25) * pi) * 0.06
            : 1.0;

        return Transform.scale(
          scale: scale,
          child: Transform.translate(
            offset: Offset(dx, 0),
            child: Opacity(
              opacity: opacity,
              child: GestureDetector(
                onTap: widget.onTap,
                child: Container(
                  width: 140,
                  decoration: BoxDecoration(
                    color: BattleColors.panel,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: 1.5),
                    boxShadow: glow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6.5),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.isCurrent)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '▶ ACTING',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: BattleColors.gold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              if (art != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5),
                                    child: SizedBox(
                                      height: 90,
                                      width: double.infinity,
                                      child: Image.asset(
                                        // Swap to the attack-pose portrait
                                        // (if one's been added for this
                                        // champion) for the duration of
                                        // their own attack glow; otherwise
                                        // the normal portrait never changes.
                                        (fxActive && _isAttackGlow)
                                            ? (attackArtFor(champ.name) ?? art)
                                            : art,
                                        fit: BoxFit.cover,
                                        alignment: Alignment.topCenter,
                                        colorBlendMode: champ.alive
                                            ? null
                                            : BlendMode.saturation,
                                        color: champ.alive ? null : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Icon(el.icon, size: 14, color: el.color),
                                    const SizedBox(width: 6),
                                    Text(
                                      champ.role.name[0].toUpperCase() +
                                          champ.role.name.substring(1),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: BattleColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  champ.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: BattleColors.cream,
                                  ),
                                ),
                              ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: Container(
                                  height: 6,
                                  color: BattleColors.bgMid,
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: hpPct,
                                    child: Container(
                                      color: hpPct > 0.4
                                          ? BattleColors.hpGreen
                                          : BattleColors.hpRed,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${champ.hp}/${champ.maxHp} HP',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: BattleColors.muted,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 2,
                                  children: [
                                    Text(
                                      '${champ.role.attackLabel} ${champ.role.usesMagic ? champ.mag : champ.atk}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: BattleColors.dim,
                                      ),
                                    ),
                                    Text(
                                      'DEF ${champ.def}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: BattleColors.dim,
                                      ),
                                    ),
                                    Text(
                                      'SPD ${champ.spd}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: BattleColors.dim,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (champ.buffs.boost > 0 ||
                                  champ.buffs.defend > 0 ||
                                  champ.buffs.weaken > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: [
                                      if (champ.buffs.boost > 0)
                                        _BuffChip(
                                          text:
                                              '+${champ.buffs.boost} ${champ.role.attackLabel}',
                                          color: BattleColors.gold,
                                        ),
                                      if (champ.buffs.defend > 0)
                                        _BuffChip(
                                          text: '+${champ.buffs.defend} DEF',
                                          color: const Color(0xFF3B8FCB),
                                          textColor: const Color(0xFF7FB8E6),
                                        ),
                                      if (champ.buffs.weaken > 0)
                                        _BuffChip(
                                          text:
                                              '-${champ.buffs.weaken} ${champ.role.attackLabel}',
                                          color: const Color(0xFFC0503F),
                                          textColor: const Color(0xFFE08A7A),
                                        ),
                                    ],
                                  ),
                                ),
                              if (!champ.alive)
                                const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Defeated',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: BattleColors.hpRed,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (fxActive && _isAttackGlow)
                          Positioned.fill(
                            child: ElementEffectOverlay(
                              element: el,
                              progress: t,
                              seed: widget.attackNonce,
                            ),
                          ),
                        if (isImpact && widget.attackerElement != null)
                          Positioned.fill(
                            child: ImpactBurstOverlay(
                              color: widget.attackerElement!.color,
                              progress: t,
                              seed: widget.attackNonce,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BuffChip extends StatelessWidget {
  const _BuffChip({required this.text, required this.color, this.textColor});

  final String text;
  final Color color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(0x33),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withAlpha(0x66)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 9, color: textColor ?? color),
      ),
    );
  }
}
