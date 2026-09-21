import 'package:flutter/material.dart';

/// How an attacker's element fares against its target's.
enum ElementMatchup { advantage, neutral, disadvantage }

/// The five elements. Each one beats exactly one other and loses to exactly
/// one other (see [beats]); every other pairing is neutral. The wheel:
/// Water > Fire > Wind > Earth > Lightning > Water.
enum GameElement {
  fire(color: Color(0xFFE2572B), icon: Icons.local_fire_department),
  water(color: Color(0xFF3B8FCB), icon: Icons.water_drop),
  earth(color: Color(0xFF6B8A4A), icon: Icons.terrain),
  wind(color: Color(0xFF9FB3C8), icon: Icons.air),
  lightning(color: Color(0xFFF0C13B), icon: Icons.bolt);

  const GameElement({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  /// The one element this element has the advantage over.
  GameElement get beats => switch (this) {
    GameElement.water => GameElement.fire,
    GameElement.fire => GameElement.wind,
    GameElement.wind => GameElement.earth,
    GameElement.earth => GameElement.lightning,
    GameElement.lightning => GameElement.water,
  };

  /// How an attack from this element fares against [target].
  ElementMatchup matchupAgainst(GameElement target) {
    if (beats == target) return ElementMatchup.advantage;
    if (target.beats == this) return ElementMatchup.disadvantage;
    return ElementMatchup.neutral;
  }
}
