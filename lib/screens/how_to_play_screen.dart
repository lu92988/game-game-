import 'package:flutter/material.dart';

import '../models/champion_role.dart';
import '../theme/battle_colors.dart';
import '../theme/body_style.dart';
import '../widgets/arena_background.dart';
import '../widgets/ornate_divider.dart';

/// Rules and mechanics reference, reachable from the title screen. The role
/// table is generated from [ChampionRole] so it can't drift from the game.
class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ArenaBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'THE ARENA OF ANCIENT POWERS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 2,
                        color: BattleColors.gold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'How to Play',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        color: BattleColors.cream,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(child: OrnateDivider()),
                    const SizedBox(height: 6),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: BattleColors.muted,
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          '‹ Back to Menu',
                          style: bodyStyle(fontSize: 13, letterSpacing: 1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _Section(
                      title: 'The Goal',
                      children: [
                        _Text(
                          'Draft a team of **3 champions** and defeat all **3 enemy '
                          'champions**. If every champion on one side falls, the other '
                          'side wins.',
                        ),
                      ],
                    ),
                    const _Section(
                      title: 'Drafting',
                      children: [
                        _Text(
                          'The roster has **30 champions**: 6 roles, each in 5 elements. '
                          'Pick any 3. The enemy team is drawn at random from the '
                          'champions you did not pick.',
                        ),
                        _Text(
                          'Hover a champion (or long-press on a phone) to see their '
                          'stats and lore.',
                        ),
                      ],
                    ),
                    const _Section(
                      title: 'Turn Order',
                      children: [
                        _Text(
                          'A battle is a series of **rounds**. In each round, every '
                          'living champion on both sides acts **once**, from highest '
                          '**SPD** to lowest. Ties are broken at random.',
                        ),
                        _Text(
                          'When champions from opposite sides tie on SPD, a **Speed '
                          'Clash** plays out: their cards collide and a coin toss '
                          'decides who acts first. Tap to skip the animation.',
                        ),
                        _Text(
                          'The order is rebuilt at the start of each round, so champions '
                          'who fell are skipped. The strip at the top of the battle '
                          'shows who has acted and who is up next.',
                        ),
                      ],
                    ),
                    const _Section(
                      title: 'Your Turn',
                      children: [
                        _Text(
                          'You control whichever of your champions is currently acting '
                          '(marked ACTING). Choose one action:',
                        ),
                        _Bullet('**Attack** – click an enemy champion.'),
                        _Bullet(
                          '**Heal** – if the acting champion is a Healer, click another '
                          'ally to restore **3 HP** (never above their max).',
                        ),
                        _Bullet(
                          '**Use an item** – click an item in your hand, then click a '
                          'target champion.',
                        ),
                        _Text(
                          'Whatever you choose uses that champion\'s turn. Enemy '
                          'champions act automatically after a short pause.',
                        ),
                      ],
                    ),
                    const _Section(
                      title: 'Roles and Stats',
                      children: [
                        _Text(
                          'Every champion\'s stats come from their role. **ATK** (or '
                          '**MAG** for Mages and Healers) is how hard they hit, **DEF** '
                          'reduces incoming damage, **SPD** sets turn order, and **HP** '
                          'is how much punishment they can take.',
                        ),
                        SizedBox(height: 8),
                        _RoleTable(),
                        SizedBox(height: 8),
                        _Text(
                          '**Crit** is the chance an attack is a critical hit. Tanks '
                          'never crit, while Rogues crit the most.',
                        ),
                      ],
                    ),
                    const _Section(
                      title: 'Damage',
                      children: [
                        _Text(
                          'A normal hit deals **attack stat − target DEF** damage, and '
                          'always at least **1**. Attack stat is ATK, or MAG for Mages '
                          'and Healers.',
                        ),
                        _Text(
                          'A **critical hit** deals about **1.5× the attack stat minus '
                          'half the target\'s DEF** (minimum 2). Tanks are resilient: '
                          'a crit against a Tank does only half damage.',
                        ),
                        _Text(
                          'Boosts, weakens, and defense buffs (below) are applied '
                          'before this math.',
                        ),
                      ],
                    ),
                    const _Section(
                      title: 'Items',
                      children: [
                        _Text(
                          'You hold a hand of **3 items**. Using one spends the '
                          'acting champion\'s turn, and a new random item replaces it.',
                        ),
                        _Bullet(
                          '**Damage Boost** – target gets **+3** to their next attack.',
                        ),
                        _Bullet(
                          '**Defense Boost** – target gets **+3 DEF** until the next '
                          'hit lands on them.',
                        ),
                        _Bullet(
                          '**Weaken** – target gets **−2 ATK/MAG** on their next attack.',
                        ),
                        _Text(
                          'There is no generic healing item. Only Healers can heal.',
                        ),
                      ],
                    ),
                    const _Section(
                      title: 'Elements',
                      children: [
                        _Text(
                          'Champions are Fire, Water, Earth, Wind, or Lightning. For '
                          'now an element is flavor only: it sets the champion\'s '
                          'colors, attack sound, and effects, and has no effect on '
                          'damage.',
                        ),
                      ],
                    ),
                    const _Section(
                      title: 'The Enemy',
                      children: [
                        _Text(
                          'Enemies attack a random living champion of yours. An enemy '
                          'Healer will often heal their most wounded ally instead.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BattleColors.panel.withAlpha(0xE6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BattleColors.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              color: BattleColors.gold,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          for (final c in children)
            Padding(padding: const EdgeInsets.only(bottom: 8), child: c),
        ],
      ),
    );
  }
}

/// Body text where `**word**` renders bold and gold-tinted.
class _Text extends StatelessWidget {
  const _Text(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text.rich(_spans(text));
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: bodyStyle(fontSize: 14, color: BattleColors.gold)),
          Expanded(child: Text.rich(_spans(text))),
        ],
      ),
    );
  }
}

TextSpan _spans(String text) {
  final parts = text.split('**');
  return TextSpan(
    children: [
      for (var i = 0; i < parts.length; i++)
        TextSpan(
          text: parts[i],
          style: i.isOdd
              ? bodyStyle(fontSize: 14, color: BattleColors.gold, height: 1.5)
              : bodyStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
        ),
    ],
  );
}

class _RoleTable extends StatelessWidget {
  const _RoleTable();

  @override
  Widget build(BuildContext context) {
    TextStyle head() =>
        bodyStyle(fontSize: 12, color: BattleColors.muted, letterSpacing: 1);
    TextStyle cell() => bodyStyle(fontSize: 13);

    Widget pad(Widget w) =>
        Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: w);

    return Table(
      columnWidths: const {0: FlexColumnWidth(1.6)},
      border: TableBorder(
        horizontalInside: BorderSide(color: BattleColors.panelBorder),
      ),
      children: [
        TableRow(
          children: [
            for (final h in ['ROLE', 'ATK/MAG', 'DEF', 'SPD', 'HP', 'CRIT'])
              pad(Text(h, style: head())),
          ],
        ),
        for (final r in ChampionRole.values)
          TableRow(
            children: [
              pad(
                Text(
                  r.name[0].toUpperCase() + r.name.substring(1),
                  style: cell().copyWith(color: BattleColors.gold),
                ),
              ),
              pad(Text('${r.attackLabel} ${r.attackStat}', style: cell())),
              pad(Text('${r.def}', style: cell())),
              pad(Text('${r.spd}', style: cell())),
              pad(Text('${r.hp}', style: cell())),
              pad(Text('${r.critFaces.length * 10}%', style: cell())),
            ],
          ),
      ],
    );
  }
}
