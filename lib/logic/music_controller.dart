import 'package:audioplayers/audioplayers.dart';

import '../data/audio_settings.dart';

const musicVolume = 0.35;
const musicAssetPath = 'music/battle_theme.mp3';

/// App-wide looping background music — a singleton, independent of whatever
/// screen is showing, so it survives Menu → Draft → Battle navigation
/// without restarting or needing to be re-plumbed per screen.
class MusicController {
  MusicController._() {
    // Keeps the already-playing track in sync when the player adjusts the
    // volume/mute control from anywhere in the app.
    AudioSettings.instance.addListener(_applyVolume);
  }

  static final MusicController instance = MusicController._();

  final AudioPlayer _player = AudioPlayer();
  bool _started = false;

  /// Starts the loop if it hasn't successfully started yet. Safe to call
  /// from multiple places (e.g. eagerly on first screen load, then again
  /// on a real button tap) — browsers block audio before a genuine user
  /// gesture, so an early attempt commonly fails silently; calling this
  /// again from a guaranteed gesture (a button's onPressed) is what
  /// actually gets it going. Failures are swallowed either way — music is
  /// polish, never something that should block the UI.
  Future<void> ensureStarted() async {
    if (_started) return;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _applyVolume();
      await _player.play(AssetSource(musicAssetPath));
      _started = true;
    } catch (_) {
      // Not started — a later ensureStarted() call (e.g. from a real
      // button press) will retry.
    }
  }

  Future<void> _applyVolume() {
    return _player.setVolume(
      musicVolume * AudioSettings.instance.effectiveVolume,
    );
  }
}
