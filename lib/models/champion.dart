import 'buffs.dart';
import 'champion_def.dart';
import 'champion_role.dart';
import 'game_element.dart';
import 'side.dart';

/// A live champion instance in a battle.
class Champion {
  Champion({
    required this.id,
    required this.side,
    required this.name,
    required this.role,
    required this.element,
    required this.atk,
    required this.mag,
    required this.def,
    required this.spd,
    required this.hp,
    required this.maxHp,
    required this.critFaces,
    this.buffs = const Buffs(),
    this.alive = true,
  });

  factory Champion.fromDef(ChampionDef def, Side side, int index) {
    final role = def.role;
    return Champion(
      id: '${side.name}-$index',
      side: side,
      name: def.name,
      role: role,
      element: def.element,
      atk: role.atk,
      mag: role.mag,
      def: role.def,
      spd: role.spd,
      hp: role.hp,
      maxHp: role.hp,
      critFaces: role.critFaces,
    );
  }

  final String id;
  final Side side;
  final String name;
  final ChampionRole role;
  final GameElement element;
  final int atk;
  final int mag;
  final int def;
  final int spd;
  final int hp;
  final int maxHp;
  final List<int> critFaces;
  final Buffs buffs;
  final bool alive;

  Champion copyWith({int? hp, bool? alive, Buffs? buffs}) => Champion(
    id: id,
    side: side,
    name: name,
    role: role,
    element: element,
    atk: atk,
    mag: mag,
    def: def,
    spd: spd,
    hp: hp ?? this.hp,
    maxHp: maxHp,
    critFaces: critFaces,
    buffs: buffs ?? this.buffs,
    alive: alive ?? this.alive,
  );
}
