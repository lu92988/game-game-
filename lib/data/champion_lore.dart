/// Placeholder lore shown on the draft screen's hover card. Same lookup-map
/// pattern as `champion_art.dart`: a champion without an entry just shows no
/// description line, so entries can be rewritten or added one at a time.
const Map<String, String> championLore = {
  // Tanks
  'Krogg':
      'A river-born toad warrior who wears the armor of the tide. He holds the '
      'ford against all comers, and nothing has ever crossed it without his leave.',
  'Oorgath':
      'An ancient moss-crusted toad who fights as if he were part of the ruins '
      'around him. Blades break on his hide long before he shows any sign of wear.',
  'Voltgraven':
      'A bronze colossus raised in a forgotten temple, still crackling with the '
      'storm that woke it. It obeys no master and remembers no war.',
  'Magmus':
      'A faceless giant of molten stone that walked out of a volcano. Wherever '
      'it stands the ground glows, and what it touches does not cool.',
  'Windhorn':
      'A rhino knight who charges in the eye of his own storm. The gales in his '
      'armor push allies forward and turn enemy blows aside.',

  // Warriors
  'Robotoman':
      'A war machine with a furnace for a heart. Built for battles long ended, '
      'it keeps fighting because no one gave the order to stop.',
  'Demon Knight':
      'A knight in frost-blue plate who traded his name for a demon\'s power. '
      'His blade is as cold as the bargain he made.',
  'Kaelvorn the Sovereign':
      'A tyrant in gold and black who rules by decree and by lightning. His '
      'banners promise order, and his armies pay for it.',
  'Gao Feng':
      'A veteran monk who fights with a polearm and no wasted motion. He moves '
      'like the wind through a mountain pass: unhurried until it strikes.',
  'Ironbark':
      'A treant knight who took up sword and shield when the forest was burned. '
      'He is slow to anger, and slower to fall.',

  // Rangers
  'Forest Child':
      'A spirit archer of the deep woods, raised by roots and moonlight. Her '
      'arrows find a target before she has finished aiming.',
  'Thundric':
      'The last archer of a storm-touched bloodline. His arrows carry lightning '
      'and never miss the one they were meant for.',
  'Talonfire':
      'A tribal hunter marked in war paint, hunting with a hawk at his shoulder. '
      'He tracks by fire and sunset, and he does not lose a trail.',
  'Nova':
      'A sniper who works from rooftops and ruined towers, her scarf snapping in '
      'the wind. She lives by one motto: higher, faster, further.',
  'Riptide':
      'A night-ops soldier who moves like the current, unseen until the moment '
      'he is on you. Silence is the only weapon he never needs to reload.',

  // Rogues
  'Thunderboy':
      'A street-fast kid who runs on borrowed lightning. He is gone before the '
      'thunder arrives, and so is whatever he came for.',
  'Vaelric':
      'A hooded mercenary with a crossbow and red eyes that never blink. He '
      'sells his skill by the coin and honors the contract, nothing more.',
  'Nyx':
      'An assassin wreathed in rainwater, with twin blades forged from a '
      'storm. She strikes from the downpour and is gone with it.',
  'Mourn':
      'A wraith of black smoke that haunts a ruined cathedral. No one has seen '
      'its face, only the red eyes and the claws.',
  'Doku':
      'A shadow of the moonlit rooftops, one katana drawn and a castle below. '
      'The contract is signed in silence and settled before dawn.',

  // Mages
  'Elder Shen':
      'A Taoist master who has meditated on the wind for a hundred years. His '
      'spells are quiet, and the gales they call are not.',
  'Vorkath':
      'A demonic sorcerer who reigns from a temple courtyard of black stone. '
      'He wields fire the way other men wield an argument.',
  'Tocho':
      'A river shaman who speaks with the waterfall and the spirits beneath '
      'it. When he calls, the water answers in a vortex.',
  'Elowen':
      'An ancient forest wizard in a leaf-brimmed hat, with a wolf, a deer and '
      'a bird at her side. The woods speak, and she alone listens.',
  'Friedrich Blitzberg':
      'A Victorian schemer who studies power and influence. His cane is charged '
      'with lightning, and his study overlooks a storm of his own making.',

  // Healers
  'Omnes':
      'An angelic keeper of a golden chapel whose light mends wounds and '
      'silences fear. Those she heals rarely remember the fight.',
  'The Cosmic Eye':
      'A watcher from a cathedral among the stars. It sees every wound before '
      'it lands, and mends what it foresaw.',
  'Cardinal Ashworth':
      'A cardinal in crimson vestments who leads a procession of embers. His '
      'blessings warm, and his sermons burn.',
  'Thalassar':
      'A priest of the sunken temple, robed in pearl beneath a trident-bearing '
      'statue. Tides answer his prayers and wounds close like ebbing water.',
  'The Hollow Shepherd':
      'A corrupted forest spirit with antlers, skulls at its belt and eyes like '
      'embers in the mist. It heals, but the cost is seldom named.',
};

String? loreFor(String championName) => championLore[championName];
