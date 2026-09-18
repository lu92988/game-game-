import 'package:flutter/material.dart';

import '../theme/battle_colors.dart';

/// A short decorative rule used under screen titles: two gold gradient
/// lines fading in from each side toward a small centered diamond.
class OrnateDivider extends StatelessWidget {
  const OrnateDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _line(leading: true),
        const SizedBox(width: 8),
        Transform.rotate(angle: 0.785398, child: Container(width: 6, height: 6, color: BattleColors.gold)),
        const SizedBox(width: 8),
        _line(leading: false),
      ],
    );
  }

  Widget _line({required bool leading}) {
    return Container(
      width: 60,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: leading ? [Colors.transparent, BattleColors.gold] : [BattleColors.gold, Colors.transparent],
        ),
      ),
    );
  }
}
