import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/menu_screen.dart';
import 'theme/battle_colors.dart';
import 'widgets/volume_control.dart';

void main() {
  runApp(const ChampionDraftBattleApp());
}

class ChampionDraftBattleApp extends StatelessWidget {
  const ChampionDraftBattleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Champion Draft Battle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: GoogleFonts.cinzel().fontFamily,
        scaffoldBackgroundColor: BattleColors.bgBottom,
        colorScheme: ColorScheme.fromSeed(
          seedColor: BattleColors.gold,
          brightness: Brightness.dark,
        ),
      ),
      home: const MenuScreen(),
      builder: (context, child) {
        return Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) =>
                  Stack(children: [?child, const VolumeControl()]),
            ),
          ],
        );
      },
    );
  }
}
