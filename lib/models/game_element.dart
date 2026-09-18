import 'package:flutter/material.dart';

/// Cosmetic element used only for flavor/icon color, not stats.
enum GameElement {
  fire(color: Color(0xFFE2572B), icon: Icons.local_fire_department),
  water(color: Color(0xFF3B8FCB), icon: Icons.water_drop),
  earth(color: Color(0xFF6B8A4A), icon: Icons.terrain),
  wind(color: Color(0xFF9FB3C8), icon: Icons.air),
  lightning(color: Color(0xFFF0C13B), icon: Icons.bolt);

  const GameElement({required this.color, required this.icon});

  final Color color;
  final IconData icon;
}
