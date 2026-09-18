import '../models/champion_def.dart';
import '../models/champion_role.dart';
import '../models/game_element.dart';

/// Fixed pool of champions. Each battle draws two disjoint random picks
/// of 3 (no name overlap between sides).
const List<ChampionDef> roster = [
  ChampionDef(name: 'Krogg', role: ChampionRole.tank, element: GameElement.water),
  ChampionDef(name: 'Oorgath', role: ChampionRole.tank, element: GameElement.earth),
  ChampionDef(name: 'Voltgraven', role: ChampionRole.tank, element: GameElement.lightning),
  ChampionDef(name: 'Magmus', role: ChampionRole.tank, element: GameElement.fire),
  ChampionDef(name: 'Windhorn', role: ChampionRole.tank, element: GameElement.wind),
  ChampionDef(name: 'Robotoman', role: ChampionRole.warrior, element: GameElement.fire),
  ChampionDef(name: 'Demon Knight', role: ChampionRole.warrior, element: GameElement.water),
  ChampionDef(name: 'Kaelvorn the Sovereign', role: ChampionRole.warrior, element: GameElement.lightning),
  ChampionDef(name: 'Gao Feng', role: ChampionRole.warrior, element: GameElement.wind),
  ChampionDef(name: 'Ironbark', role: ChampionRole.warrior, element: GameElement.earth),
  ChampionDef(name: 'Forest Child', role: ChampionRole.ranger, element: GameElement.earth),
  ChampionDef(name: 'Thundric', role: ChampionRole.ranger, element: GameElement.lightning),
  ChampionDef(name: 'Talonfire', role: ChampionRole.ranger, element: GameElement.fire),
  ChampionDef(name: 'Nova', role: ChampionRole.ranger, element: GameElement.wind),
  ChampionDef(name: 'Riptide', role: ChampionRole.ranger, element: GameElement.water),
  ChampionDef(name: 'Thunderboy', role: ChampionRole.rogue, element: GameElement.lightning),
  ChampionDef(name: 'Vaelric', role: ChampionRole.rogue, element: GameElement.fire),
  ChampionDef(name: 'Nyx', role: ChampionRole.rogue, element: GameElement.water),
  ChampionDef(name: 'Mourn', role: ChampionRole.rogue, element: GameElement.wind),
  ChampionDef(name: 'Doku', role: ChampionRole.rogue, element: GameElement.earth),
  ChampionDef(name: 'Elder Shen', role: ChampionRole.mage, element: GameElement.wind),
  ChampionDef(name: 'Vorkath', role: ChampionRole.mage, element: GameElement.fire),
  ChampionDef(name: 'Tocho', role: ChampionRole.mage, element: GameElement.water),
  ChampionDef(name: 'Elowen', role: ChampionRole.mage, element: GameElement.earth),
  ChampionDef(name: 'Friedrich Blitzberg', role: ChampionRole.mage, element: GameElement.lightning),
  ChampionDef(name: 'Omnes', role: ChampionRole.healer, element: GameElement.wind),
  ChampionDef(name: 'The Cosmic Eye', role: ChampionRole.healer, element: GameElement.lightning),
  ChampionDef(name: 'Cardinal Ashworth', role: ChampionRole.healer, element: GameElement.fire),
  ChampionDef(name: 'Thalassar', role: ChampionRole.healer, element: GameElement.water),
  ChampionDef(name: 'The Hollow Shepherd', role: ChampionRole.healer, element: GameElement.earth),
];
