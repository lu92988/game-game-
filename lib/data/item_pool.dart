import '../models/game_item.dart';

/// `Heal` was deliberately removed from this pool — healing should only
/// come from the Healer role, to make drafting one matter. Do not re-add a
/// generic heal item without discussing it first.
const List<GameItem> itemPool = [
  GameItem(name: 'Damage Boost', type: ItemType.boost, desc: '+3 to next attack'),
  GameItem(name: 'Defense Boost', type: ItemType.defend, desc: '+3 Def until the next hit lands'),
  GameItem(name: 'Weaken', type: ItemType.weaken, desc: 'Target -2 Atk/Mag next turn'),
];
