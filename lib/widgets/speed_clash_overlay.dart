import 'dart:math';

import 'package:flutter/material.dart';

import '../data/champion_art.dart';
import '../logic/battle_engine.dart';
import '../models/champion.dart';
import '../models/side.dart';
import '../theme/battle_colors.dart';
import '../theme/body_style.dart';

/// Full-screen "speed clash" moment shown when champions from opposing sides
/// tie on SPD: both cards slam together, a coin is tossed, and the winner
/// (already decided by the round's shuffle) is revealed as acting first.
/// Tap anywhere to skip.
class SpeedClashOverlay extends StatefulWidget {
  const SpeedClashOverlay({
    super.key,
    required this.clash,
    required this.onDone,
  });

  final SpeedClash clash;
  final VoidCallback onDone;

  @override
  State<SpeedClashOverlay> createState() => _SpeedClashOverlayState();
}

class _SpeedClashOverlayState extends State<SpeedClashOverlay>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 4800);
  late final AnimationController _c;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: _duration)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _finish();
      })
      ..forward();
  }

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static double _seg(double t, double a, double b) =>
      ((t - a) / (b - a)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final winner = widget.clash.winner;
    final loser = widget.clash.loser;
    // The winner is shown on the left when it is the player's champion, so
    // the player's side is consistently the left card.
    final left = winner.side == Side.player ? winner : loser;
    final right = identical(left, winner) ? loser : winner;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final backdrop = _seg(t, 0, 0.06) * (1 - _seg(t, 0.95, 1));
          return LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth;
              final cardW = w < 440 ? 112.0 : 150.0;
              final cardH = cardW * 1.38;
              final restX = cardW / 2 + 46;
              final touchX = cardW / 2 + 5;

              // Cards: fly in (0–0.22), slam + shake (0.22–0.40), recoil so
              // the coin has room (0.30–0.40).
              final fly = Curves.easeInCubic.transform(_seg(t, 0.04, 0.22));
              final recoil = Curves.easeOut.transform(_seg(t, 0.30, 0.40));
              final shakeT = _seg(t, 0.22, 0.42);
              final shake = sin(shakeT * pi * 9) * 9 * (1 - shakeT);
              final startX = w / 2 + cardW;
              var dist = startX + (touchX - startX) * fly;
              dist += (restX - touchX) * recoil;

              final reveal = Curves.easeOutBack.transform(_seg(t, 0.84, 0.94));

              Widget cardFor(Champion c, {required bool isLeft}) {
                final isWinner = identical(c, winner);
                final emphasis = isWinner ? reveal : -reveal;
                final dir = isLeft ? -1.0 : 1.0;
                final tilt = (1 - fly) * 0.35 * dir * -1;
                return Transform.translate(
                  offset: Offset(dir * dist + (t < 0.42 ? shake * dir : 0), 0),
                  child: Transform.rotate(
                    angle: tilt,
                    child: Transform.scale(
                      scale:
                          1 +
                          0.12 * max(emphasis, 0) -
                          0.06 * max(-emphasis, 0),
                      child: Opacity(
                        opacity: 1 - 0.55 * max(-emphasis, 0),
                        child: _ClashCard(
                          champion: c,
                          width: cardW,
                          height: cardH,
                          glow: max(emphasis, 0),
                        ),
                      ),
                    ),
                  ),
                );
              }

              final title = Curves.easeOutBack.transform(_seg(t, 0.02, 0.14));

              return Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: Colors.black.withAlpha((0xE0 * backdrop).round()),
                  ),
                  Opacity(
                    opacity: backdrop,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Transform.scale(
                          scale: 0.6 + 0.4 * title,
                          child: Opacity(
                            opacity: title.clamp(0.0, 1.0),
                            child: const Text(
                              'SPEED CLASH',
                              style: TextStyle(
                                fontSize: 30,
                                letterSpacing: 6,
                                color: BattleColors.gold,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Opacity(
                          opacity: _seg(t, 0.08, 0.18),
                          child: Text(
                            'Both champions have ${winner.spd} SPD. A coin will decide who acts first.',
                            textAlign: TextAlign.center,
                            style: bodyStyle(fontSize: 13),
                          ),
                        ),
                        SizedBox(
                          height: cardH + 190,
                          width: double.infinity,
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _ClashPainter(
                                    progress: _seg(t, 0.20, 0.55),
                                  ),
                                ),
                              ),
                              cardFor(left, isLeft: true),
                              cardFor(right, isLeft: false),
                              _Coin(t: t, front: winner, back: loser),
                            ],
                          ),
                        ),
                        Opacity(
                          opacity: reveal.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: 0.8 + 0.2 * reveal.clamp(0.0, 1.0),
                            child: Text(
                              '${winner.name} acts first!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                color: BattleColors.gold,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Opacity(
                          opacity: 0.6 * _seg(t, 0.15, 0.25),
                          child: Text(
                            'Tap to skip',
                            style: bodyStyle(
                              fontSize: 11,
                              color: BattleColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ClashCard extends StatelessWidget {
  const _ClashCard({
    required this.champion,
    required this.width,
    required this.height,
    required this.glow,
  });

  final Champion champion;
  final double width;
  final double height;
  final double glow;

  @override
  Widget build(BuildContext context) {
    final el = champion.element;
    final art = artFor(champion.name);
    final isPlayer = champion.side == Side.player;
    final accent = isPlayer ? BattleColors.gold : BattleColors.hpRed;

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: BattleColors.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent, width: 2),
        boxShadow: [
          BoxShadow(
            color: el.color.withAlpha((0x88 + 0x77 * glow).round()),
            blurRadius: 14 + 22 * glow,
            spreadRadius: 1 + 5 * glow,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isPlayer ? 'YOU' : 'ENEMY',
            textAlign: TextAlign.center,
            style: bodyStyle(fontSize: 10, color: accent, letterSpacing: 2),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: art != null
                  ? Image.asset(
                      art,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    )
                  : Container(
                      color: BattleColors.bgMid,
                      child: Icon(el.icon, color: el.color, size: 40),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(el.icon, size: 13, color: el.color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  champion.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: bodyStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'SPD ${champion.spd}',
            textAlign: TextAlign.center,
            style: bodyStyle(fontSize: 10, color: BattleColors.gold),
          ),
        ],
      ),
    );
  }
}

/// The tossed coin. Front face is the winner, back face the loser, and the
/// flip count is fixed so it always lands showing the winner.
class _Coin extends StatelessWidget {
  const _Coin({required this.t, required this.front, required this.back});

  final double t;
  final Champion front;
  final Champion back;

  static double _seg(double t, double a, double b) =>
      ((t - a) / (b - a)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final appear = Curves.easeOutBack.transform(_seg(t, 0.30, 0.38));
    if (appear <= 0) return const SizedBox.shrink();

    final p = _seg(t, 0.42, 0.80);
    final flip = Curves.easeOut.transform(p) * 2 * pi * 6;
    final height = -4 * p * (1 - p) * 150;
    final peakScale = 1 + 0.45 * (4 * p * (1 - p));
    final bounce = -sin(_seg(t, 0.80, 0.87) * pi) * 12;
    final fadeOut = 1 - _seg(t, 0.90, 0.97);

    final showFront = cos(flip) >= 0;
    final face = _CoinFace(champion: showFront ? front : back);

    return Opacity(
      opacity: fadeOut,
      child: Transform.translate(
        offset: Offset(0, height + bounce),
        child: Transform.scale(
          scale: appear * peakScale,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0025)
              ..rotateX(flip),
            child: showFront
                ? face
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationX(pi),
                    child: face,
                  ),
          ),
        ),
      ),
    );
  }
}

class _CoinFace extends StatelessWidget {
  const _CoinFace({required this.champion});

  final Champion champion;

  @override
  Widget build(BuildContext context) {
    final art = artFor(champion.name);
    final el = champion.element;
    return Container(
      width: 84,
      height: 84,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF2D675), BattleColors.gold, Color(0xFF7A5F12)],
        ),
        boxShadow: [
          BoxShadow(
            color: el.color.withAlpha(0xAA),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: art != null
            ? Image.asset(
                art,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              )
            : Container(
                color: BattleColors.bgMid,
                child: Icon(el.icon, color: el.color, size: 34),
              ),
      ),
    );
  }
}

class _ClashPainter extends CustomPainter {
  const _ClashPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final center = Offset(size.width / 2, size.height / 2);

    final flash = (1 - (progress / 0.25).clamp(0.0, 1.0));
    if (flash > 0) {
      canvas.drawCircle(
        center,
        70 + 90 * progress,
        Paint()..color = Colors.white.withAlpha((0xBB * flash).round()),
      );
    }

    for (var ring = 0; ring < 2; ring++) {
      final rp = ((progress - ring * 0.12) / (1 - ring * 0.12)).clamp(0.0, 1.0);
      if (rp <= 0) continue;
      canvas.drawCircle(
        center,
        rp * size.width * 0.42,
        Paint()
          ..color = (ring == 0 ? BattleColors.gold : BattleColors.hpRed)
              .withAlpha(((1 - rp) * 220).round())
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 * (1 - rp) + 1,
      );
    }

    final rand = Random(11);
    final line = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < 18; i++) {
      final angle = rand.nextDouble() * pi * 2;
      final speed = 120 + rand.nextDouble() * 200;
      final delay = rand.nextDouble() * 0.2;
      final t = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (t <= 0 || t >= 1) continue;
      final dir = Offset(cos(angle), sin(angle));
      final from = center + dir * (t * speed);
      final to = center + dir * (t * speed + 18 * (1 - t) + 4);
      line
        ..color = (i.isEven ? BattleColors.gold : const Color(0xFFFFF1B8))
            .withAlpha(((1 - t) * 255).round())
        ..strokeWidth = 3 * (1 - t) + 1;
      canvas.drawLine(from, to, line);
    }
  }

  @override
  bool shouldRepaint(covariant _ClashPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
