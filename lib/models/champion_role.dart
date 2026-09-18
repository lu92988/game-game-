/// Base stats per role. Mages use MAG instead of ATK for attack damage;
/// every other role uses ATK. Healers' MAG currently does nothing (heals
/// are a flat amount, not stat-scaled).
enum ChampionRole {
  warrior(atk: 8, mag: 2, hp: 7, spd: 4, def: 6, critFaces: [10]),
  tank(atk: 3, mag: 2, hp: 9, spd: 3, def: 9, critFaces: []),
  ranger(atk: 6, mag: 3, hp: 5, spd: 8, def: 4, critFaces: [9, 10]),
  rogue(atk: 6, mag: 2, hp: 4, spd: 10, def: 3, critFaces: [8, 9, 10]),
  mage(atk: 2, mag: 9, hp: 4, spd: 5, def: 3, critFaces: [10]),
  healer(atk: 2, mag: 8, hp: 5, spd: 6, def: 5, critFaces: [10]);

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

  /// d10 faces (1-10) that count as a critical hit for this role.
  final List<int> critFaces;
}
