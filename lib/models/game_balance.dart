/// Every stat, heal and item amount is its original ("base") value times
/// [statScale]. Doubling everything keeps fights the same length while giving
/// damage room to be split more finely, so the element multipliers (x1.5 and
/// x0.75) do not round away on small hits. Change this one number to rescale
/// the whole game. SPD and crit chances are not scaled.
const int statScale = 2;

/// HP restored by a Healer's heal (base 3).
const int healAmount = 3 * statScale;

/// Damage Boost: added to the target's next attack (base +3).
const int boostAmount = 3 * statScale;

/// Defense Boost: added to the target's DEF until the next hit (base +3).
const int defendAmount = 3 * statScale;

/// Weaken: subtracted from the target's next attack (base -2).
const int weakenAmount = 2 * statScale;
