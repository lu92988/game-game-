import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/music_controller.dart';
import '../theme/battle_colors.dart';
import '../widgets/arena_background.dart';
import '../widgets/ornate_divider.dart';
import 'draft_screen.dart';

/// The game's title screen — first thing the player sees. A single way
/// forward (into the draft), no settings/menu items yet since none exist.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  void initState() {
    super.initState();
    // Try immediately in case the browser's audio context is already
    // unlocked (e.g. a prior interaction this session). Browsers commonly
    // block this before any real gesture, so this often silently no-ops —
    // the Listener below and the button handlers are what actually get it
    // going on a fresh load.
    MusicController.instance.ensureStarted();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // Catches the very first tap/click anywhere on the title screen —
      // that's the user gesture browsers require before audio can play,
      // so music starts as soon as the player touches the page at all,
      // not only if/when they press a specific button.
      onPointerDown: (_) => MusicController.instance.ensureStarted(),
      child: Scaffold(
        body: ArenaBackground(
          imageAsset: 'assets/images/menu_background.png',
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'THE ARENA OF ANCIENT POWERS',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, letterSpacing: 3, color: BattleColors.gold),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Champion Draft Battle',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 42, color: BattleColors.cream, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 14),
                      const OrnateDivider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Draft three champions. Master speed, elements, and the turn order.\n'
                        'Only one side leaves the arena.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: BattleColors.muted, height: 1.5),
                      ),
                      const SizedBox(height: 36),
                      ElevatedButton(
                        onPressed: () {
                          MusicController.instance.ensureStarted();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const DraftScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BattleColors.gold,
                          foregroundColor: const Color(0xFF14121A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                          textStyle: const TextStyle(fontSize: 15, letterSpacing: 1),
                        ),
                        child: const Text('Enter the Arena'),
                      ),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: () => SystemNavigator.pop(),
                        style: TextButton.styleFrom(foregroundColor: BattleColors.muted),
                        child: const Text('Exit', style: TextStyle(fontSize: 13, letterSpacing: 1)),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
