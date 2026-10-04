/// Maps a champion name to a wide "lore scene" shot (the champion in battle
/// or somewhere from their story), shown as a banner across the top of the
/// draft screen's hover / press-and-hold card. Champions without an entry
/// just show the card without a banner — same graceful-fallback pattern as
/// [championArt] in `champion_art.dart`, so this can be filled in one
/// champion at a time.
const Map<String, String> championSceneArt = {};

String? sceneArtFor(String championName) => championSceneArt[championName];
