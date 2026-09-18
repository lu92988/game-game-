import 'package:flutter/foundation.dart';

/// App-wide audio preference (volume + mute), shared by every screen. A
/// plain singleton `ChangeNotifier` rather than a state-management package
/// — the only listeners are [VolumeControl] and whichever controller owns
/// the active audio players.
class AudioSettings extends ChangeNotifier {
  AudioSettings._();

  static final AudioSettings instance = AudioSettings._();

  double _volume = 0.7;
  bool _muted = false;

  double get volume => _volume;
  bool get muted => _muted;

  /// What players should actually use: 0 when muted, otherwise the raw
  /// volume. Multiply a sound's own base level by this.
  double get effectiveVolume => _muted ? 0 : _volume;

  void setVolume(double value) {
    _volume = value.clamp(0.0, 1.0);
    if (_volume > 0 && _muted) _muted = false;
    notifyListeners();
  }

  void toggleMute() {
    _muted = !_muted;
    notifyListeners();
  }
}
