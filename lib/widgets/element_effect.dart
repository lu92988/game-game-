import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/game_element.dart';

/// A short procedural VFX burst layered over a champion's card while they
/// attack — different shape language per element (embers for fire, a
/// ripple + droplets for water, flying debris for earth, gust streaks for
/// wind, forking bolts + a flash for lightning). Pure vector drawing, no
/// image/particle assets: [seed] (the controller's attack nonce) reseeds a
/// [Random] identically every frame, so each particle's position is a pure
/// function of (seed, progress) rather than accumulated frame-to-frame
/// state — the burst looks alive without the widget needing to store a
/// particle list itself.
class ElementEffectOverlay extends StatelessWidget {
  const ElementEffectOverlay({
    super.key,
    required this.element,
    required this.progress,
    required this.seed,
  });

  final GameElement element;
  final double progress;
  final int seed;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ElementEffectPainter(
          element: element,
          progress: progress,
          seed: seed,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _ElementEffectPainter extends CustomPainter {
  const _ElementEffectPainter({
    required this.element,
    required this.progress,
    required this.seed,
  });

  final GameElement element;
  final double progress;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    switch (element) {
      case GameElement.fire:
        _paintFire(canvas, size);
      case GameElement.water:
        _paintWater(canvas, size);
      case GameElement.earth:
        _paintEarth(canvas, size);
      case GameElement.wind:
        _paintWind(canvas, size);
      case GameElement.lightning:
        _paintLightning(canvas, size);
    }
  }

  void _paintFire(Canvas canvas, Size size) {
    final rand = Random(seed);
    const colorA = Color(0xFFFFD23B);
    const colorB = Color(0xFFE2572B);

    final flashT = (progress / 0.25).clamp(0.0, 1.0);
    final flashAlpha = ((1 - flashT) * 70).round().clamp(0, 255);
    if (flashAlpha > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = colorB.withAlpha(flashAlpha),
      );
    }

    for (var i = 0; i < 12; i++) {
      final baseX = rand.nextDouble() * size.width;
      final delay = rand.nextDouble() * 0.35;
      final speed = size.height * (0.7 + rand.nextDouble() * 0.5);
      final wobbleSeed = rand.nextDouble() * 10;
      final startRadius = 2.5 + rand.nextDouble() * 2.5;
      final colorMix = rand.nextDouble();

      final t = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (t <= 0 || t >= 1) continue;

      final wobble = sin(progress * 14 + wobbleSeed) * 5 * t;
      final x = (baseX + wobble).clamp(0.0, size.width);
      final y = size.height - t * speed;
      if (y < -10) continue;

      final radius = startRadius * (1 - t * 0.7);
      final alpha = ((1 - t) * 235).round().clamp(0, 255);
      final paint = Paint()
        ..color = Color.lerp(colorA, colorB, colorMix)!.withAlpha(alpha);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  void _paintWater(Canvas canvas, Size size) {
    final rand = Random(seed);
    const color = Color(0xFF6FB8E6);
    final center = Offset(size.width / 2, size.height * 0.55);

    for (var ring = 0; ring < 3; ring++) {
      final delay = ring * 0.12;
      final t = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (t <= 0 || t >= 1) continue;
      final radius = t * size.width * 0.55;
      final alpha = ((1 - t) * 200).round().clamp(0, 255);
      final paint = Paint()
        ..color = color.withAlpha(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * (1 - t) + 0.5;
      canvas.drawCircle(center, radius, paint);
    }

    for (var i = 0; i < 8; i++) {
      final angle = rand.nextDouble() * pi * 2;
      final delay = rand.nextDouble() * 0.3;
      final dist = 20 + rand.nextDouble() * 30;
      final t = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (t <= 0 || t >= 1) continue;
      final drop = t * t * 18;
      final x = center.dx + cos(angle) * dist * t;
      final y = center.dy + sin(angle) * dist * t + drop;
      final alpha = ((1 - t) * 220).round().clamp(0, 255);
      canvas.drawCircle(
        Offset(x, y),
        2 + rand.nextDouble() * 1.5,
        Paint()..color = color.withAlpha(alpha),
      );
    }
  }

  void _paintEarth(Canvas canvas, Size size) {
    final rand = Random(seed);
    const colorA = Color(0xFF8A7A5A);
    const colorB = Color(0xFF6B8A4A);
    final center = Offset(size.width / 2, size.height * 0.62);

    final dustT = (progress).clamp(0.0, 1.0);
    final dustAlpha = (sin(dustT * pi) * 90).round().clamp(0, 255);
    if (dustAlpha > 0) {
      canvas.drawCircle(
        center,
        size.width * (0.25 + dustT * 0.25),
        Paint()
          ..color = colorA.withAlpha(dustAlpha)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8),
      );
    }

    for (var i = 0; i < 9; i++) {
      final angle = rand.nextDouble() * pi * 2;
      final speed = 18 + rand.nextDouble() * 26;
      final size0 = 2 + rand.nextDouble() * 2.5;
      final t = progress;
      final gravity = t * t * 14;
      final x = center.dx + cos(angle) * speed * t;
      final y = center.dy + sin(angle) * speed * t * 0.6 + gravity;
      final alpha = ((1 - t) * 220).round().clamp(0, 255);
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: size0, height: size0),
        Paint()..color = (i.isEven ? colorA : colorB).withAlpha(alpha),
      );
    }
  }

  void _paintWind(Canvas canvas, Size size) {
    final rand = Random(seed);
    const color = Color(0xFFD8E2E8);

    for (var i = 0; i < 4; i++) {
      final delay = i * 0.15;
      final t = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (t <= 0 || t >= 1) continue;
      final yBase = size.height * (0.25 + i * 0.18) + rand.nextDouble() * 6;
      final xStart = -20 + t * (size.width + 40) - 30;
      final sweep = 26 + rand.nextDouble() * 10;
      final alpha = ((sin(t * pi)) * 190).round().clamp(0, 255);

      final path = Path()
        ..moveTo(xStart, yBase)
        ..quadraticBezierTo(
          xStart + sweep / 2,
          yBase - 8,
          xStart + sweep,
          yBase,
        );

      canvas.drawPath(
        path,
        Paint()
          ..color = color.withAlpha(alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintLightning(Canvas canvas, Size size) {
    final rand = Random(seed);
    const color = Color(0xFFF0C13B);

    final flashT = (progress / 0.18).clamp(0.0, 1.0);
    final flashAlpha = ((1 - flashT) * 90).round().clamp(0, 255);
    if (flashAlpha > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.white.withAlpha(flashAlpha),
      );
    }

    for (var bolt = 0; bolt < 2; bolt++) {
      final delay = bolt * 0.1;
      final t = ((progress - delay) / (0.5)).clamp(0.0, 1.0);
      if (t <= 0 || t >= 1) continue;
      final alpha = ((1 - t) * 235).round().clamp(0, 255);

      final startX = size.width * (0.25 + bolt * 0.35) + rand.nextDouble() * 10;
      var x = startX;
      var y = 0.0;
      final path = Path()..moveTo(x, y);
      final steps = 5;
      for (var s = 1; s <= steps; s++) {
        y = size.height * s / steps;
        x += (rand.nextDouble() - 0.5) * 22;
        path.lineTo(x, y);
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = color.withAlpha((alpha * 0.4).round())
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withAlpha(alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ElementEffectPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.element != element ||
      oldDelegate.seed != seed;
}

/// The impact side of an attack — layered on the *target's* card, colored
/// by whichever element hit them. Deliberately generic/shape-agnostic
/// (a flash + an expanding shockwave ring + a few outward sparks) rather
/// than reusing each element's [ElementEffectOverlay] cast animation,
/// which is built around that element's own casting motif (rising embers,
/// bolts, etc.) and would look like the target were casting the spell
/// themselves rather than being hit by it.
class ImpactBurstOverlay extends StatelessWidget {
  const ImpactBurstOverlay({
    super.key,
    required this.color,
    required this.progress,
    required this.seed,
  });

  final Color color;
  final double progress;
  final int seed;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ImpactBurstPainter(
          color: color,
          progress: progress,
          seed: seed,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _ImpactBurstPainter extends CustomPainter {
  const _ImpactBurstPainter({
    required this.color,
    required this.progress,
    required this.seed,
  });

  final Color color;
  final double progress;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final center = Offset(size.width / 2, size.height / 2);

    // Quick white flash right at the moment of impact.
    final flashT = (progress / 0.15).clamp(0.0, 1.0);
    final flashAlpha = ((1 - flashT) * 130).round().clamp(0, 255);
    if (flashAlpha > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.white.withAlpha(flashAlpha),
      );
    }

    // Expanding, fading shockwave ring in the attacker's element color.
    final ringAlpha = ((1 - progress) * 200).round().clamp(0, 255);
    canvas.drawCircle(
      center,
      progress * size.width * 0.7,
      Paint()
        ..color = color.withAlpha(ringAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * (1 - progress) + 1,
    );

    // A handful of sparks flung outward from the point of impact.
    final rand = Random(seed + 1);
    for (var i = 0; i < 10; i++) {
      final angle = rand.nextDouble() * pi * 2;
      final speed = 30 + rand.nextDouble() * 40;
      final delay = rand.nextDouble() * 0.25;
      final t = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (t <= 0 || t >= 1) continue;
      final dist = t * speed;
      final pos = center + Offset(cos(angle), sin(angle)) * dist;
      final alpha = ((1 - t) * 220).round().clamp(0, 255);
      canvas.drawCircle(
        pos,
        2.5 * (1 - t) + 1,
        Paint()..color = color.withAlpha(alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ImpactBurstPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.seed != seed;
}
