import 'package:flutter/material.dart';

import '../data/audio_settings.dart';
import '../theme/battle_colors.dart';

/// Persistent bottom-left mute/volume control, floated over every screen
/// via [MaterialApp.builder] rather than added to each screen individually.
class VolumeControl extends StatelessWidget {
  const VolumeControl({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      bottom: 16,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: AudioSettings.instance,
          builder: (context, _) {
            final settings = AudioSettings.instance;
            final isMuted = settings.muted || settings.volume == 0;
            return Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: BattleColors.panel.withAlpha(0xD8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: BattleColors.panelBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: settings.toggleMute,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          isMuted ? Icons.volume_off : Icons.volume_up,
                          color: BattleColors.gold,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 84,
                      height: 20,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 12,
                          ),
                          activeTrackColor: BattleColors.gold,
                          inactiveTrackColor: BattleColors.panelBorder,
                          thumbColor: BattleColors.gold,
                          overlayColor: BattleColors.gold.withAlpha(0x33),
                        ),
                        child: Slider(
                          value: isMuted ? 0 : settings.volume,
                          onChanged: settings.setVolume,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
