import 'package:flutter/material.dart';

import '../theme/battle_colors.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.text, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: 1.5,
          color: BattleColors.muted,
        ).merge(style),
      ),
    );
  }
}
