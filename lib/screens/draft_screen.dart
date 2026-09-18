import 'package:flutter/material.dart';

import '../data/champion_art.dart';
import '../logic/music_controller.dart';
import '../data/roster.dart';
import '../models/champion_def.dart';
import '../models/champion_role.dart';
import '../theme/battle_colors.dart';
import '../widgets/arena_background.dart';
import '../widgets/ornate_divider.dart';
import '../widgets/section_label.dart';
import 'battle_screen.dart';

/// Lets the player pick their 3 champions before a battle. The enemy team
/// is still drafted at random (from whatever's left) once the battle starts.
class DraftScreen extends StatefulWidget {
  const DraftScreen({super.key});

  @override
  State<DraftScreen> createState() => _DraftScreenState();
}

class _DraftScreenState extends State<DraftScreen> {
  final List<ChampionDef> _picks = [];

  void _toggle(ChampionDef def) {
    setState(() {
      if (_picks.contains(def)) {
        _picks.remove(def);
      } else if (_picks.length < 3) {
        _picks.add(def);
      }
    });
  }

  void _begin() {
    MusicController.instance.ensureStarted();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BattleScreen(playerPicks: List.of(_picks))),
    );
  }

  Widget _buildArchetypeGroup(ChampionRole role) {
    return Column(
      children: [
        SectionLabel(text: role.name[0].toUpperCase() + role.name.substring(1)),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final def in roster.where((d) => d.role == role))
              _RosterCard(
                def: def,
                selected: _picks.contains(def),
                selectionOrder: _picks.contains(def) ? _picks.indexOf(def) + 1 : null,
                disabled: !_picks.contains(def) && _picks.length >= 3,
                onTap: () => _toggle(def),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = _picks.length == 3;

    return Scaffold(
      body: ArenaBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  children: [
                    const Text(
                      'THE ARENA OF ANCIENT POWERS',
                      style: TextStyle(fontSize: 12, letterSpacing: 2, color: BattleColors.gold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Choose Your Champions',
                      style: TextStyle(fontSize: 28, color: BattleColors.cream, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    const OrnateDivider(),
                    const SizedBox(height: 6),
                    if (Navigator.of(context).canPop())
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: BattleColors.muted,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          '‹ Back to Menu',
                          style: TextStyle(fontSize: 12, letterSpacing: 1),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Pick 3 — ${_picks.length}/3 selected',
                      style: const TextStyle(fontSize: 13, color: BattleColors.muted, letterSpacing: 1),
                    ),
                    const SizedBox(height: 20),
                    for (var i = 0; i < ChampionRole.values.length; i += 2)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildArchetypeGroup(ChampionRole.values[i])),
                            const SizedBox(width: 16),
                            if (i + 1 < ChampionRole.values.length)
                              Expanded(child: _buildArchetypeGroup(ChampionRole.values[i + 1]))
                            else
                              const Expanded(child: SizedBox.shrink()),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: ready ? _begin : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BattleColors.gold,
                        foregroundColor: const Color(0xFF14121A),
                        disabledBackgroundColor: BattleColors.panelBorder,
                        disabledForegroundColor: BattleColors.dim,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      ),
                      child: const Text('Begin Battle'),
                    ),
                    const SizedBox(height: 24),
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

class _RosterCard extends StatelessWidget {
  const _RosterCard({
    required this.def,
    required this.selected,
    required this.selectionOrder,
    required this.disabled,
    required this.onTap,
  });

  final ChampionDef def;
  final bool selected;
  final int? selectionOrder;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final el = def.element;
    final role = def.role;
    final art = artFor(def.name);

    final Color borderColor = selected ? BattleColors.gold : el.color.withAlpha(0x55);

    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: BattleColors.panel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: selected ? 2 : 1.5),
            boxShadow: selected
                ? [BoxShadow(color: BattleColors.gold.withAlpha(0xAA), spreadRadius: 2, blurRadius: 0)]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (art != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: SizedBox(
                          height: 90,
                          width: double.infinity,
                          child: Image.asset(art, fit: BoxFit.cover, alignment: Alignment.topCenter),
                        ),
                      ),
                      if (selectionOrder != null)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: BattleColors.gold, shape: BoxShape.circle),
                            child: Text(
                              '$selectionOrder',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF14121A),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Icon(el.icon, size: 14, color: el.color),
                  const SizedBox(width: 6),
                  Text(
                    role.name[0].toUpperCase() + role.name.substring(1),
                    style: const TextStyle(fontSize: 10, color: BattleColors.muted),
                  ),
                  if (art == null && selectionOrder != null) ...[
                    const Spacer(),
                    Container(
                      width: 16,
                      height: 16,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: BattleColors.gold, shape: BoxShape.circle),
                      child: Text(
                        '$selectionOrder',
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF14121A)),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(def.name, style: const TextStyle(fontSize: 14, color: BattleColors.cream)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 2,
                children: [
                  Text('ATK ${role.atk}', style: const TextStyle(fontSize: 10, color: BattleColors.dim)),
                  Text('DEF ${role.def}', style: const TextStyle(fontSize: 10, color: BattleColors.dim)),
                  Text('SPD ${role.spd}', style: const TextStyle(fontSize: 10, color: BattleColors.dim)),
                  Text('HP ${role.hp}', style: const TextStyle(fontSize: 10, color: BattleColors.dim)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
