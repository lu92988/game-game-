/// Champion lore shown on the draft screen's hover card. Same lookup-map
/// pattern as `champion_art.dart`: a champion without an entry just shows no
/// description line, so entries can be rewritten or added one at a time.
const Map<String, String> championLore = {
  // Tanks
  'Krogg':
      'Brother to Oorgath and one of the two guardians of the ancient library, '
      'where all the world\'s secrets are kept. Like the tide, he never leaves '
      'his post, and nothing gets past him.',
  'Oorgath':
      'Brother to Krogg and one of the two guardians of the ancient library, '
      'where all the world\'s secrets are kept. Rooted like the stone around '
      'him, he has never once let an intruder through.',
  'Voltgraven':
      'A colossal war machine built by the Enlightened to fight in the Ancient '
      'War. The war has long since ended, but the storm that powers it has '
      'never gone quiet.',
  'Magmus':
      'Forged by Vorkath, the Dark One, from the molten heart of the earth. It '
      'was made for one purpose only: chaos.',
  'Windhorn':
      'Guardian of the monks\' temple high in the mountains, home of Elder Shen '
      'and Gao Feng. He stands watch at its gates, and no one reaches them '
      'without first getting past him.',

  // Warriors
  'Robotoman':
      'Just an ordinary accountant, or so he believed. Then destiny came '
      'calling, and he awoke to the truth: he is the reborn soul of a '
      'legendary fire warrior.',
  'Demon Knight':
      'An ancient spirit bound to the Dark One. Across hundreds of years of '
      'war he has never once faltered, and now he stands at his master\'s '
      'right hand.',
  'Kaelvorn the Sovereign':
      'Father of Thunderboy, and half-divine himself, he was born with the '
      'strength to be a great hero. Instead, he bends the knee to the Dark '
      'One.',
  'Gao Feng':
      'Right hand to Elder Shen, he wants nothing more than peace and '
      'stillness. But peace must be protected, so he takes up arms to defend '
      'the last hope of that dream.',
  'Ironbark':
      'Elowen\'s mightiest creation, forged in the days when his master still '
      'walked with the dark. When Elowen found the light, he could not bring '
      'Ironbark with him. Now the great guardian of nature is a tool in '
      'Vorkath\'s hands.',

  // Rangers
  'Forest Child':
      'A half-divine child of unknown origin, who never fails to appear '
      'wherever the light needs defending.',
  'Thundric':
      'A guiding light to his younger brother, Thunderboy. He has sworn his '
      'whole existence to one purpose: keeping him safe, whatever the cost.',
  'Talonfire':
      'Once a warrior of Tocho\'s tribe, sworn to hunt those who wound the '
      'land. But the fire within him burned too hot to control, and it led him '
      'to the Dark One. Now his arrows serve the very darkness he once hunted.',
  'Nova':
      'A gifted soldier whose marksmanship borders on the unnatural. Entire '
      'nations fear the day she takes aim at them.',
  'Riptide':
      'Once a special ops commando who fought for the light, he lost his way '
      'and now sells his gun to the highest bidder. His soul belongs to the '
      'Dark One.',

  // Rogues
  'Thunderboy':
      'Son of Kaelvorn the Sovereign, he carries divine blood in his veins. '
      'He is still only a boy, and he has no idea that he is the key to '
      'everything.',
  'Vaelric':
      'In all the Yamikawa clan, only Nyx surpassed him. That single fact '
      'poisoned him. Jealousy drove him into isolation, and in the end, out '
      'of the clan entirely.',
  'Nyx':
      'Even among the deadly Yamikawa assassin clan, he stands apart. The '
      'water in his blood makes him a blade no one sees coming, and Vaelric '
      'has never forgiven him for it.',
  'Mourn':
      'Little is known of this entity. Some say it is the darkness in the '
      'hearts of men given form; others say it is chaos itself. Whatever the '
      'truth, one thing is certain: it serves the Dark One.',
  'Doku':
      'Born in squalor and destined for a life in chains, misery drove him to '
      'radical beliefs. To provide for those he loved, he became a master '
      'thief and a shadow assassin. Brushes with death awakened powers buried '
      'deep within him, and in time, he made them his own.',

  // Mages
  'Elder Shen':
      'The heir to thousands of years of heritage, Elder Shen descends from '
      'the mightiest bloodline that never bent to the Dark One. Gao Feng '
      'stands at his side as his right hand.',
  'Vorkath':
      'The one they call the Dark One: an ancient spirit who dares to '
      'challenge the old gods themselves. He means to tear down the world as '
      'we know it and raise a new one in his own image.',
  'Tocho':
      'A shaman of an ancient tribe that walks the path of enlightenment and '
      'listens to the land. The waters answer his call, and he uses them to '
      'save lives and mend the wounds mankind leaves behind.',
  'Elowen':
      'One of the few mortals ever to cheat death. His command of the earth '
      'is so complete, and his legend so full of wonders, that many believe '
      'he is a god.',
  'Friedrich Blitzberg':
      'Like Elowen, he found the secret to immortality, but he chose a darker '
      'path. Centuries of hoarded knowledge have made him rich and powerful, '
      'and all of it now serves the Dark One and his promised utopia.',

  // Healers
  'Omnes':
      'One of the four Covenants. His divine innocence lets him heal any '
      'wound, and in the rarest of moments, even undo death itself.',
  'The Cosmic Eye':
      'One of the four Covenants, and the greatest mystery among them. Almost '
      'nothing is known of him, save this: he stands above even the divine.',
  'Cardinal Ashworth':
      'Next in line to lead the faith, he carries a fire that could burn '
      'kingdoms to ash. Yet he is a man of peace, and that flame is spent only '
      'on healing those in need.',
  'Thalassar':
      'A gentle soul who hears the ocean and the spirits that dwell within '
      'it. His command of the tides is among the greatest the world has ever '
      'known.',
  'The Hollow Shepherd':
      'When Elowen found the light, he cast out the darkness within him. But '
      'that darkness did not die. It lingered, festered, and took a form of '
      'its own: the Hollow Shepherd.',
};

String? loreFor(String championName) => championLore[championName];
