/// Maps a champion name to an alternate "attack pose" portrait, shown in
/// place of their normal portrait for the brief window they're the
/// attacker. Champions without an entry here just keep showing their
/// normal portrait for the whole attack — same graceful-fallback pattern
/// as [championArt] in `champion_art.dart`, so this can be filled in one
/// champion at a time without anything looking broken in the meantime.
const Map<String, String> championAttackArt = {};

String? attackArtFor(String championName) => championAttackArt[championName];
