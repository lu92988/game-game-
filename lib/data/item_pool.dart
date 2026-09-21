import '../models/game_balance.dart';
import '../models/game_item.dart';

/// `Heal` was deliberately removed from this pool — healing should only
/// come from the Healer role, to make drafting one matter. Do not re-add a
/// generic heal item without discussing it first.
const List<GameItem> itemPool = [
  GameItem(
    name: 'Damage Boost',
    type: ItemType.boost,
    desc: '+$boostAmount to next attack',
  ),
  GameItem(
    name: 'Defense Boost',
    type: ItemType.defend,
    desc: '+$defendAmount Def until the next hit lands',
  ),
  GameItem(
    name: 'Weaken',
    type: ItemType.weaken,
    desc: 'Target -$weakenAmount Atk/Mag next turn',
  ),
];
