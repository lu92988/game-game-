enum ItemType { boost, defend, weaken }

/// An item drawn into the player's hand. Any item can target any living
/// ally (Weaken currently isn't side-restricted either, matching the
/// prototype — worth deciding deliberately later).
class GameItem {
  const GameItem({required this.name, required this.type, required this.desc});

  final String name;
  final ItemType type;
  final String desc;
}
