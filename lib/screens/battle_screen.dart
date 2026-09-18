import 'package:flutter/material.dart';

import '../logic/battle_controller.dart';
import '../models/champion.dart';
import '../models/champion_def.dart';
import '../models/champion_role.dart';
import '../models/side.dart';
import '../theme/battle_colors.dart';
import '../widgets/arena_background.dart';
import '../widgets/battle_log.dart';
import '../widgets/champion_card.dart';
import '../widgets/initiative_strip.dart';
import '../widgets/item_hand.dart';
import '../widgets/ornate_divider.dart';
import '../widgets/section_label.dart';

class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key, required this.playerPicks});

  final List<ChampionDef> playerPicks;

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  late final BattleController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BattleController(playerPicks: widget.playerPicks)
      ..addListener(_onControllerChanged);
  }

  void _onControllerChanged() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  /// Mirrors the player row's onClick gating in the original prototype: a
  /// tap only reaches [BattleController.handleTargetClick] when it's the
  /// player's turn and either an item is pending, or the acting champion is
  /// a Healer targeting a different ally.
  void _onPlayerCardTap(Champion c) {
    final controller = _controller;
    if (controller.winner != null || !c.alive) return;
    final actor = controller.currentActor;
    if (actor == null || actor.side != Side.player) return;
    if (controller.pendingItem != null) {
      controller.handleTargetClick(c);
      return;
    }
    if (actor.role == ChampionRole.healer && actor.id != c.id) {
      controller.handleTargetClick(c);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final currentActor = controller.currentActor;
    final winner = controller.winner;

    return Scaffold(
      body: ArenaBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: Column(
                  children: [
                    _buildHeader(context),
                    if (winner != null) _buildWinnerBanner(winner),
                    if (winner == null)
                      InitiativeStrip(
                        roundOrder: controller.roundOrder,
                        player: controller.player,
                        enemy: controller.enemy,
                        actedIds: controller.actedIds,
                        currentActorId: currentActor?.id,
                      ),
                    const SectionLabel(text: 'Opponent'),
                    _buildRow(
                      controller.enemy,
                      clickable:
                          currentActor != null &&
                          currentActor.side == Side.player &&
                          winner == null,
                      onTap: (c) => controller.handleTargetClick(c),
                    ),
                    const SizedBox(height: 12),
                    const SectionLabel(text: 'Your Team'),
                    _buildRow(
                      controller.player,
                      clickable:
                          currentActor != null &&
                          currentActor.side == Side.player &&
                          winner == null &&
                          (controller.pendingItem != null ||
                              (currentActor.role == ChampionRole.healer)),
                      currentActorId: currentActor?.id,
                      isPlayerRow: true,
                      winner: winner,
                    ),
                    const SizedBox(height: 8),
                    const SectionLabel(text: 'Hand'),
                    ItemHand(
                      hand: controller.hand,
                      pendingItem: controller.pendingItem,
                      usable:
                          currentActor != null &&
                          currentActor.side == Side.player &&
                          winner == null,
                      onSelect: controller.togglePendingItem,
                    ),
                    const SizedBox(height: 8),
                    _buildStatusLine(currentActor, winner),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text(
                        winner == null
                            ? 'Turn order is set by Speed each round — fastest champions act first.'
                            : '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: BattleColors.dim,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    BattleLog(entries: controller.log),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          const Text(
            'THE ARENA OF ANCIENT POWERS',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 2,
              color: BattleColors.gold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Champion Draft Battle',
            style: TextStyle(
              fontSize: 28,
              color: BattleColors.cream,
              fontWeight: FontWeight.w600,
            ),
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
                '‹ Change Champions',
                style: TextStyle(fontSize: 12, letterSpacing: 1),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWinnerBanner(Side winner) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BattleColors.panel,
        border: Border.all(color: BattleColors.gold),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            winner == Side.player ? 'Victory.' : 'Defeat.',
            style: const TextStyle(fontSize: 20, color: BattleColors.gold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: BattleColors.cream,
                  side: const BorderSide(color: BattleColors.muted),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                ),
                child: const Text('‹ Change Champions'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => _controller.resetBattle(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BattleColors.gold,
                  foregroundColor: const Color(0xFF14121A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                ),
                child: const Text('New Battle'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    List<Champion> champs, {
    required bool clickable,
    void Function(Champion)? onTap,
    String? currentActorId,
    bool isPlayerRow = false,
    Side? winner,
  }) {
    final controller = _controller;
    final activeId = currentActorId ?? controller.currentActor?.id;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final c in champs)
          ChampionCard(
            champ: c,
            isCurrent: activeId == c.id,
            clickable: clickable && c.alive,
            disabled: isPlayerRow
                ? (!c.alive || winner != null || activeId != c.id)
                : false,
            onTap: isPlayerRow
                ? () => _onPlayerCardTap(c)
                : (onTap == null ? null : () => onTap(c)),
            attackNonce: controller.attackNonce,
            attackerId: controller.lastAttackerId,
            targetId: controller.lastTargetId,
            attackerElement: controller.lastAttackerElement,
          ),
      ],
    );
  }

  Widget _buildStatusLine(Champion? currentActor, Side? winner) {
    String text;
    if (winner != null || currentActor == null) {
      text = '';
    } else if (currentActor.side == Side.enemy) {
      text = "${currentActor.name}'s turn...";
    } else if (_controller.pendingItem != null) {
      text =
          '${currentActor.name} — choose a target for ${_controller.pendingItem!.name}.';
    } else if (currentActor.role == ChampionRole.healer) {
      text =
          '${currentActor.name} — click an ally to heal, an enemy to attack, or an item to use.';
    } else {
      text =
          '${currentActor.name} — click an enemy to attack, or an item to use.';
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 16,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: BattleColors.muted),
        ),
      ),
    );
  }
}
