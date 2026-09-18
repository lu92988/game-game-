/// Active buffs/debuffs on a champion. None expire on a round timer — each
/// persists until the specific event it affects occurs, then clears itself:
/// boost/weaken clear after the champion's next attack, defend clears after
/// the champion's next incoming hit.
class Buffs {
  const Buffs({this.boost = 0, this.defend = 0, this.weaken = 0});

  final int boost;
  final int defend;
  final int weaken;

  Buffs copyWith({int? boost, int? defend, int? weaken}) => Buffs(
    boost: boost ?? this.boost,
    defend: defend ?? this.defend,
    weaken: weaken ?? this.weaken,
  );
}
