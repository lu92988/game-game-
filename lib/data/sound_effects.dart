import '../models/game_element.dart';

/// Maps an element to its attack sound effect, when one exists.
/// Paths are relative to the assets root (no leading `assets/`) since
/// that's the convention `audioplayers`' `AssetSource` expects.
/// Elements without an entry simply play nothing.
const Map<GameElement, String> elementSfx = {
  GameElement.fire: 'sfx/fire.mp3',
  GameElement.water: 'sfx/water.mp3',
  GameElement.earth: 'sfx/earth.mp3',
  GameElement.wind: 'sfx/wind.mp3',
  GameElement.lightning: 'sfx/lightning.mp3',
};

String? sfxFor(GameElement element) => elementSfx[element];
