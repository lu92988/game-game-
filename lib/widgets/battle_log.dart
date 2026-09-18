import 'package:flutter/material.dart';

import '../theme/battle_colors.dart';

class BattleLog extends StatelessWidget {
  const BattleLog({super.key, required this.entries});

  final List<String> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 160),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: BattleColors.logBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: BattleColors.logBorder),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < entries.length; i++)
              Opacity(
                opacity: i == 0 ? 1 : 0.55,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    entries[i],
                    style: const TextStyle(fontSize: 13, color: BattleColors.cream, height: 1.2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
