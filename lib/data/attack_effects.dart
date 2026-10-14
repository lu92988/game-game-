/// A champion's own attack effect, cut from its pixel art sheet by
/// art/sprites/build_effects.ps1. A beam (or projectile trail) stretches
/// from the attacker to the target, drawn with its big end at the target; a
/// ground effect (spikes, thorns) erupts under the target.
class AttackEffect {
  const AttackEffect.beam(this.asset, this.width, this.height) : ground = false;
  const AttackEffect.ground(this.asset, this.width, this.height)
    : ground = true;

  final String asset;

  /// The image's size in pixels, for keeping its proportions on screen.
  final int width;
  final int height;
  final bool ground;
}

/// Champions without an entry (Gao Feng, Vaelric and Thunderboy, whose
/// sheets draw the effect around the fighter) use the game's own
/// element projectile.
const Map<String, AttackEffect> attackEffects = {
  'Cardinal Ashworth': AttackEffect.beam(
    'assets/effects/cardinal_ashworth.png',
    725,
    147,
  ),
  'Windhorn': AttackEffect.beam('assets/effects/windhorn.png', 548, 170),
  'Tocho': AttackEffect.beam('assets/effects/tocho.png', 524, 166),
  'Nyx': AttackEffect.beam('assets/effects/nyx.png', 625, 178),
  'Thalassar': AttackEffect.beam('assets/effects/thalassar.png', 584, 119),
  'Mourn': AttackEffect.beam('assets/effects/mourn.png', 489, 238),
  'Friedrich Blitzberg': AttackEffect.beam(
    'assets/effects/friedrich_blitzberg.png',
    678,
    193,
  ),
  'Demon Knight': AttackEffect.beam(
    'assets/effects/demon_knight.png',
    687,
    185,
  ),
  'Voltgraven': AttackEffect.beam('assets/effects/voltgraven.png', 573, 167),
  'Ironbark': AttackEffect.ground('assets/effects/ironbark.png', 221, 137),
  'Thundric': AttackEffect.beam('assets/effects/thundric.png', 703, 192),
  'Elowen': AttackEffect.ground('assets/effects/elowen.png', 249, 183),
  'Omnes': AttackEffect.beam('assets/effects/omnes.png', 883, 145),
  'The Cosmic Eye': AttackEffect.beam(
    'assets/effects/cosmic_eye.png',
    1088,
    150,
  ),
  'The Hollow Shepherd': AttackEffect.beam(
    'assets/effects/hollow_shepherd.png',
    585,
    141,
  ),
  'Elder Shen': AttackEffect.beam('assets/effects/elder_shen.png', 760, 125),
  'Magmus': AttackEffect.beam('assets/effects/magmus.png', 532, 167),
  'Robotoman': AttackEffect.beam('assets/effects/robotoman.png', 833, 170),
  'Riptide': AttackEffect.beam('assets/effects/riptide.png', 777, 170),
  'Forest Child': AttackEffect.beam(
    'assets/effects/forest_child.png',
    798,
    130,
  ),
  'Kaelvorn the Sovereign': AttackEffect.beam(
    'assets/effects/kaelvorn.png',
    727,
    183,
  ),
  'Nova': AttackEffect.beam('assets/effects/nova.png', 418, 134),
  'Oorgath': AttackEffect.ground('assets/effects/oorgath.png', 196, 111),
  'Vorkath': AttackEffect.beam('assets/effects/vorkath.png', 732, 145),
  'Talonfire': AttackEffect.beam('assets/effects/talonfire.png', 798, 155),
  'Doku': AttackEffect.ground('assets/effects/doku.png', 173, 121),
  'Krogg': AttackEffect.beam('assets/effects/krogg.png', 541, 186),
};
