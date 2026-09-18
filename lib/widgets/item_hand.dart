import 'package:flutter/material.dart';

import '../models/game_item.dart';
import '../theme/battle_colors.dart';

class ItemHand extends StatelessWidget {
  const ItemHand({
    super.key,
    required this.hand,
    required this.pendingItem,
    required this.usable,
    required this.onSelect,
  });

  final List<GameItem> hand;
  final GameItem? pendingItem;
  final bool usable;
  final ValueChanged<GameItem> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final item in hand)
          _ItemButton(
            item: item,
            isPending: identical(pendingItem, item),
            usable: usable,
            onTap: () => onSelect(item),
          ),
      ],
    );
  }
}

class _ItemButton extends StatelessWidget {
  const _ItemButton({
    required this.item,
    required this.isPending,
    required this.usable,
    required this.onTap,
  });

  final GameItem item;
  final bool isPending;
  final bool usable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: usable ? onTap : null,
      child: Container(
        constraints: const BoxConstraints(minWidth: 130),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isPending ? const Color(0xFF3A3242) : BattleColors.panel,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isPending ? BattleColors.gold : BattleColors.panelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: usable ? BattleColors.cream : const Color(0xFF6B6577),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.desc,
              style: TextStyle(
                fontSize: 11,
                color: (usable ? BattleColors.cream : const Color(0xFF6B6577)).withAlpha(0xBF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
