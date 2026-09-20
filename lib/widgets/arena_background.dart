import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/battle_colors.dart';

/// Shared atmospheric backdrop for every screen: a full-bleed painted
/// battlefield behind everything, darkened by a top-to-bottom scrim and a
/// radial vignette so UI text stays readable over the art, plus a faint
/// scattering of dust/ember motes for extra texture.
class ArenaBackground extends StatelessWidget {
  const ArenaBackground({
    super.key,
    required this.child,
    this.imageAsset = 'assets/images/arena_background.png',
  });

  final Widget child;

  /// Which full-bleed art to use behind the scrim/vignette. Screens can
  /// pass their own (e.g. the menu screen's hero shot) instead of the
  /// default in-battle backdrop.
  final String imageAsset;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: BattleColors.bgBottom),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              imageAsset,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      BattleColors.bgTop.withAlpha(0x9E),
                      BattleColors.bgMid.withAlpha(0xC8),
                      BattleColors.bgBottom.withAlpha(0xF0),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.1,
                    colors: [Colors.transparent, Colors.black.withAlpha(0x80)],
                    stops: const [0.55, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: const _DustPainter()),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _DustPainter extends CustomPainter {
  const _DustPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rand = Random(7);
    for (var i = 0; i < 70; i++) {
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * size.height;
      final r = 0.4 + rand.nextDouble() * 1.3;
      final alpha = (10 + rand.nextDouble() * 26).round();
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = BattleColors.gold.withAlpha(alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DustPainter oldDelegate) => false;
}
