import 'game_balance.dart';

/// Base stats per role. Mages and Healers attack with MAG instead of ATK;
/// every other role uses ATK. Heals are a flat amount, not stat-scaled.
enum ChampionRole {
  warrior(
    atk: 8 * statScale,
    mag: 2 * statScale,
    hp: 7 * statScale,
    spd: 4,
    def: 6 * statScale,
    critFaces: [10],
  ),
  tank(
    atk: 3 * statScale,
    mag: 2 * statScale,
    hp: 9 * statScale,
    spd: 3,
    def: 9 * statScale,
    critFaces: [],
  ),
  ranger(
    atk: 6 * statScale,
    mag: 3 * statScale,
    hp: 5 * statScale,
    spd: 8,
    def: 4 * statScale,
    critFaces: [9, 10],
  ),
  rogue(
    atk: 6 * statScale,
    mag: 2 * statScale,
    hp: 4 * statScale,
    spd: 10,
    def: 3 * statScale,
    critFaces: [8, 9, 10],
  ),
  mage(
    atk: 2 * statScale,
    mag: 9 * statScale,
    hp: 4 * statScale,
    spd: 5,
    def: 3 * statScale,
    critFaces: [10],
  ),
  healer(
    atk: 2 * statScale,
    mag: 8 * statScale,
    hp: 5 * statScale,
    spd: 6,
    def: 5 * statScale,
    critFaces: [10],
  );

  const ChampionRole({
    required this.atk,
    required this.mag,
    required this.hp,
    required this.spd,
    required this.def,
    required this.critFaces,
  });

  final int atk;
  final int mag;
  final int hp;
  final int spd;
  final int def;

  bool get usesMagic => this == mage || this == healer;

  String get attackLabel => usesMagic ? 'MAG' : 'ATK';

  int get attackStat => usesMagic ? mag : atk;

  /// d10 faces (1-10) that count as a critical hit for this role.
  final List<int> critFaces;
}
