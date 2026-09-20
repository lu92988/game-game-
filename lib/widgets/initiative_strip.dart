import 'package:flutter/material.dart';

import '../logic/battle_engine.dart';
import '../models/champion.dart';
import '../models/side.dart';
import '../theme/battle_colors.dart';

class InitiativeStrip extends StatelessWidget {
  const InitiativeStrip({
    super.key,
    required this.roundOrder,
    required this.player,
    required this.enemy,
    required this.actedIds,
    required this.currentActorId,
  });

  final List<String> roundOrder;
  final List<Champion> player;
  final List<Champion> enemy;
  final List<String> actedIds;
  final String? currentActorId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final id in roundOrder)
            if (findChampion(player, id) ?? findChampion(enemy, id)
                case final c?)
              _buildChip(c),
        ],
      ),
    );
  }

  Widget _buildChip(Champion c) {
    final isCurrent = currentActorId == c.id;
    final hasActed = actedIds.contains(c.id);

    final Color background = isCurrent
        ? BattleColors.gold
        : c.side == Side.player
        ? BattleColors.panel
        : BattleColors.enemyRowBg;

    final Color textColor = isCurrent
        ? const Color(0xFF14121A)
        : !c.alive
        ? BattleColors.faint
        : hasActed
        ? BattleColors.dim
        : BattleColors.muted;

    return Opacity(
      opacity: hasActed && !isCurrent ? 0.5 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isCurrent ? BattleColors.gold : BattleColors.panelBorder,
          ),
        ),
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 10,
              color: textColor,
              decoration: c.alive
                  ? TextDecoration.none
                  : TextDecoration.lineThrough,
              fontFamily: 'Georgia',
            ),
            children: [
              TextSpan(text: c.name),
              TextSpan(
                text: ' (${c.spd})',
                style: TextStyle(color: textColor.withAlpha(0xB3)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
