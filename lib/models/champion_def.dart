import 'champion_role.dart';
import 'game_element.dart';

/// A roster entry: name + role + cosmetic element. Used to spawn a live
/// [Champion] for a battle.
class ChampionDef {
  const ChampionDef({
    required this.name,
    required this.role,
    required this.element,
  });

  final String name;
  final ChampionRole role;
  final GameElement element;
}
