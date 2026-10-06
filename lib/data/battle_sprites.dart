import 'package:flutter/painting.dart';

/// A hand-drawn pixel-art battle sprite, facing right. Each string is one
/// row of pixels; each character is a key into [palette] and '.' is
/// transparent. The grid is [size] pixels square, and the sprite is
/// bottom-aligned so every champion stands on the same ground line.
class PixelSprite {
  const PixelSprite(this.rows, this.palette, {this.size = 32});

  final List<String> rows;
  final Map<String, Color> palette;
  final int size;
}

/// The layout unit the battle screen sizes fighters by. Sprites of any
/// grid size are scaled to fill the same on-screen box.
const spriteSize = 24;

/// Real artwork for a champion's battle sprite (for example pixel art made
/// in an image tool), drawn facing right on a transparent background.
/// When a champion has an entry here it is used instead of the hand-drawn
/// grid in [battleSprites]. Same lookup-map pattern as `champion_art.dart`.
const Map<String, String> battleSpriteImages = {};

String? spriteImageFor(String championName) => battleSpriteImages[championName];

/// Which row of an animation sheet to play.
enum SpritePose { idle, attack, hurt, death }

/// An animated sprite sheet: a grid of [frameSize] frames, [frames] per
/// row, one row per [SpritePose] in order (idle, attack, hurt, death), on
/// a transparent background. [facesLeft] marks art drawn facing left; it
/// is mirrored so every champion faces the other team.
class SpriteSheet {
  const SpriteSheet(
    this.asset, {
    this.frameSize = 32,
    this.frames = 4,
    this.facesLeft = false,
  });

  final String asset;
  final int frameSize;
  final int frames;
  final bool facesLeft;
}

/// Animated artwork. Takes priority over [battleSpriteImages] and the
/// hand-drawn grids. The source SVGs live in `art/sprites/`.
const Map<String, SpriteSheet> battleSpriteSheets = {
  // Drawn with the sword on the left, so mirrored to point it at the foe.
  'Demon Knight': SpriteSheet(
    'assets/sprites/demon_knight.png',
    facesLeft: true,
  ),
  'Thunderboy': SpriteSheet('assets/sprites/thunderboy.png'),
  'Robotoman': SpriteSheet('assets/sprites/robotoman.png'),
  'Riptide': SpriteSheet('assets/sprites/riptide.png'),
  // 128x128 frames (a 512x512 sheet). The 32x32 krogg.png is kept as a
  // backup; swap the asset and frameSize back to use it.
  'Krogg': SpriteSheet('assets/sprites/krogg_128.png', frameSize: 128),
  'Friedrich Blitzberg': SpriteSheet('assets/sprites/friedrich_blitzberg.png'),
};

SpriteSheet? spriteSheetFor(String championName) =>
    battleSpriteSheets[championName];

String _d(int n) => '.' * n;

/// Writes [puts] (row, column, pixels) over [rows], for details like
/// weapons, capes and shields that cross the body. '_' in a put leaves the
/// pixel underneath unchanged.
List<String> _put(List<String> rows, List<(int, int, String)> puts) {
  final out = [...rows];
  for (final (r, c, s) in puts) {
    while (out.length <= r) {
      out.add('');
    }
    final chars = out[r].padRight(c + s.length, '.').split('');
    for (var i = 0; i < s.length; i++) {
      if (s[i] != '_') chars[c + i] = s[i];
    }
    out[r] = chars.join();
  }
  return out;
}

/// Hand-drawn 32x32 stand-ins until real artwork is added to
/// [battleSpriteImages]. Champions with neither aren't shown yet.
final Map<String, PixelSprite> battleSprites = {
  'Robotoman': PixelSprite(
    [
      '${_d(15)}Y',
      '${_d(14)}YOY',
      '${_d(13)}ROYOR',
      '${_d(12)}ROOYYOR',
      '${_d(12)}kkkkkkkk',
      '${_d(11)}kHLLLLLLMk',
      '${_d(10)}kHLLLLLLLMDk',
      '${_d(10)}kLLMMMMMMMDk',
      '${_d(10)}kLMkkkkkkkDk',
      '${_d(10)}kMkOOOYOYYkk',
      '${_d(10)}kMMkkkkkkkDk',
      '${_d(11)}kDMMMMMMDk',
      '${_d(12)}kkDOODkk',
      '${_d(8)}kkkkkkkkkkkkkkkk',
      '${_d(7)}kHLLkDMMMMMMDkLLHk',
      '${_d(7)}kLMMkMMOYYOMMkMMLk',
      '${_d(7)}kMDDkMOYYYYOMkDDMk',
      '${_d(7)}kkkkkMMOYYOMMkkkkk',
      '${_d(9)}kMkDMMRRMMDkMk',
      '${_d(9)}kLkDMOMMMMDkLk',
      '${_d(9)}kMkkDDDDDDkkMk',
      '${_d(9)}kOkkOOYYOOkkOk',
      '${_d(8)}kOYOkkkkkkkkOYOk',
      '${_d(8)}kkkkkkDMMDkkkkkk',
      '${_d(12)}kDMMMMDk',
      '${_d(12)}kMDkkDMk',
      '${_d(12)}kLOkkOLk',
      '${_d(12)}kMDkkDMk',
      '${_d(12)}kMRkkRMk',
      '${_d(11)}kLMMkkLMMMk',
      '${_d(11)}kDDDkkDDDDk',
      '${_d(11)}kkkkkkkkkkk',
    ],
    const {
      'k': Color(0xFF17131A),
      'D': Color(0xFF3E383C),
      'M': Color(0xFF6A6166),
      'L': Color(0xFF8A8086),
      'H': Color(0xFFB0A8AC),
      'O': Color(0xFFFF7A1A),
      'Y': Color(0xFFFFD23F),
      'R': Color(0xFFC2361B),
    },
  ),
  'Thunderboy': PixelSprite(
    [
      '',
      '',
      '${_d(10)}kk..kkkk',
      '${_d(9)}kHHkkHHHHk',
      '${_d(10)}kHHHHHHHHHk',
      '${_d(9)}kHHHHHHHHHHk${_d(3)}Y',
      '${_d(10)}kHHHHHSSSSk',
      '${_d(11)}kHHSSSSSSk',
      '${_d(11)}kHSSSSSESk',
      '${_d(11)}kHSSSSSSSk',
      '${_d(6)}Y${_d(5)}kSSSSmSk',
      '${_d(13)}kSSSSk',
      '${_d(14)}kSSk',
      '${_d(11)}kkAAAAAAkk',
      '${_d(10)}kAAAAAAAAAAk',
      '${_d(9)}kBkACAAAACAkAk',
      '${_d(9)}kBkACAAAACAkAk',
      '${_d(9)}kBkACAAAACAkSk',
      '${_d(9)}kBkAAAAAAAAkSk${_d(2)}Y',
      '${_d(9)}kSkBBBBBBBBkSk',
      '${_d(9)}kkkCCCCCCCCkkk',
      '${_d(12)}kLLLLLLk',
      '${_d(12)}kLLkkLLk',
      '${_d(12)}kLLkkLLk',
      '${_d(12)}kLLkkLLk',
      '${_d(7)}Y${_d(4)}kLLkkLLk',
      '${_d(12)}kLLkkLLk',
      '${_d(12)}kLLkkLLk',
      '${_d(12)}kLLkkLLk',
      '${_d(11)}kTTTkkTTTTk',
      '${_d(11)}kBBBkkBBBBk',
      '${_d(11)}kkkkkkkkkkk',
    ],
    const {
      'k': Color(0xFF1A1418),
      'H': Color(0xFFF0C84A),
      'S': Color(0xFFF2C9A0),
      'E': Color(0xFF2A6FD6),
      'm': Color(0xFFB07A60),
      'A': Color(0xFFF2F0EA),
      'B': Color(0xFFC8C4BC),
      'C': Color(0xFF2A2A2E),
      'L': Color(0xFF2A2A2E),
      'T': Color(0xFFF2F0EA),
      'Y': Color(0xFFFFF27A),
    },
  ),
  'Krogg': PixelSprite(
    _put(
      [
        '${_d(22)}W.W.W',
        '${_d(22)}WWWWW',
        '',
        '${_d(11)}kkk..kkk',
        '${_d(10)}kGwEkkGwEk',
        '${_d(9)}kGGGGGGGGGGGk',
        '${_d(9)}kGGGGGGGGGGGk',
        '${_d(9)}kGGGGGGGGGGGk',
        '${_d(9)}kGMMMMMMMMMGk',
        '${_d(10)}kgggggggggk',
        '${_d(11)}kgggggggk',
        '${_d(12)}kkkkkkk',
        '${_d(8)}kkkkkkkkkkkkkkkk',
        '${_d(7)}kCAAkAAACCAAAkAACk',
        '${_d(7)}kAAAkAACCCCAAkAAAk',
        '${_d(7)}kBBBkAACCCCAAkBBBk',
        '${_d(7)}kkkkkAAACCAAAkkkkk',
        '${_d(9)}kGkBAAAAAABkGk',
        '${_d(9)}kGkBAAAAAABkGk',
        '${_d(9)}kGkkCCCCCCkkGk',
        '${_d(9)}kGkkBBBBBBkkGk',
        '${_d(8)}kGGGkkkkkkkkGGGk',
        '${_d(8)}kkkkkkAAAAkkkkkk',
        '${_d(12)}kAAAAAAk',
        '${_d(12)}kAAkkAAk',
        '${_d(12)}kAAkkAAk',
        '${_d(12)}kCCkkCCk',
        '${_d(12)}kAAkkAAk',
        '${_d(12)}kAAkkAAk',
        '${_d(11)}kTTTkkTTTTk',
        '${_d(11)}kTTTkkTTTTk',
        '${_d(11)}kkkkkkkkkkk',
      ],
      [
        // Trident shaft, held in the front hand.
        for (var r = 2; r <= 30; r++) (r, 24, 'W'),
        // Shield on the back arm, with a silver wave.
        (13, 3, 'kkkk'),
        (14, 2, 'kDDDDk'),
        (15, 2, 'kDCCDk'),
        (16, 2, 'kDDCCk'),
        (17, 2, 'kDCCDk'),
        (18, 2, 'kDCDDk'),
        (19, 2, 'kDDDDk'),
        (20, 3, 'kkkk'),
      ],
    ),
    const {
      'k': Color(0xFF141A1C),
      'G': Color(0xFF4F7A5A),
      'g': Color(0xFFC9CF9A),
      'w': Color(0xFFF2F2E8),
      'E': Color(0xFF1A1418),
      'M': Color(0xFF2F4A36),
      'A': Color(0xFF2F5F9E),
      'B': Color(0xFF1F3F6E),
      'C': Color(0xFFE8EEF5),
      'D': Color(0xFF2A56A0),
      'T': Color(0xFF9AA3AD),
      'W': Color(0xFFB8C4CF),
    },
  ),
  'Demon Knight': PixelSprite(
    _put(
      [
        '',
        '${_d(13)}bbb',
        '${_d(12)}bbkkkkk',
        '${_d(12)}kHHHHHHk',
        '${_d(11)}kHLLLLLLHk',
        '${_d(11)}kHHHHHHHHk',
        '${_d(11)}kHHHHHHHHk',
        '${_d(11)}kHHkkkkkkk',
        '${_d(11)}kHHHkHkHkk',
        '${_d(11)}kHHHHHHHHk',
        '${_d(12)}kHHHHHHk',
        '${_d(13)}kHHHHk',
        '${_d(13)}kkkkkk',
        '${_d(8)}kkkkkkkkkkkkkkkk',
        '${_d(7)}kLAAkAAAAAAAAkAALk',
        '${_d(7)}kAAAkAACCCCAAkAAAk',
        '${_d(7)}kBBBkAAACCAAAkBBBk',
        '${_d(7)}kkkkkAAACCAAAkkkkk',
        '${_d(9)}kAkBAAAAAABkAk',
        '${_d(9)}kAkBBAAAABBkAk',
        '${_d(9)}kBkkCCCCCCkkBk',
        '${_d(8)}kSSSkkAAAAkkSSSk',
        '${_d(8)}kkkkkkBAABkkkkkk',
        '${_d(12)}kAAAAAAk',
        '${_d(12)}kAAkkAAk',
        '${_d(12)}kLAkkLAk',
        '${_d(12)}kAAkkAAk',
        '${_d(12)}kBAkkBAk',
        '${_d(12)}kAAkkAAk',
        '${_d(11)}kLAAkkLAAAk',
        '${_d(11)}kAAAkkAAAAk',
        '${_d(11)}kkkkkkkkkkk',
      ],
      [
        // Cape flowing behind.
        for (var r = 14; r <= 17; r++) (r, 5, 'kc'),
        for (var r = 18; r <= 20; r++) (r, 4, 'kcccc'),
        (21, 4, 'kccc'),
        (22, 4, 'kccc'),
        (23, 4, 'kcccccc'),
        for (var r = 24; r <= 26; r++) (r, 5, 'kcccccc'),
        (27, 6, 'kccccc'),
        (28, 6, 'kccccc'),
        (29, 7, 'kccc'),
        (30, 7, 'kccc'),
        (31, 7, 'kkkk'),
        // Water sword raised in the front hand.
        (4, 24, 'W'),
        for (var r = 5; r <= 19; r++) (r, 24, 'WV'),
        (20, 22, 'gggg'),
        (21, 24, 'h'),
        (22, 24, 'g'),
      ],
    ),
    const {
      'k': Color(0xFF15161C),
      'b': Color(0xFF4A90D9),
      'H': Color(0xFFC7CCD4),
      'L': Color(0xFFE8ECF2),
      'A': Color(0xFFB0B7C2),
      'B': Color(0xFF7D8794),
      'C': Color(0xFF3D7FD0),
      'S': Color(0xFF9AA3AD),
      'W': Color(0xFF9FD8FF),
      'V': Color(0xFF5FB0E8),
      'g': Color(0xFF6A7380),
      'h': Color(0xFF4A3A2A),
      'c': Color(0xFF2D5F9E),
    },
  ),
  'Friedrich Blitzberg': PixelSprite(
    _put(
      [
        '',
        '',
        '',
        '${_d(13)}kkkkkk',
        '${_d(12)}kHHHHHHk',
        '${_d(11)}kHHHHHHHHk',
        '${_d(11)}kHHHHSSSSk',
        '${_d(11)}kHHSSSSSSk',
        '${_d(11)}kHSSSSSESk',
        '${_d(11)}kHSSSSSSSk',
        '${_d(12)}kSSSSmSk',
        '${_d(13)}kSSSSk',
        '${_d(14)}kwwk',
        '${_d(11)}kkAAwwAAkk',
        '${_d(10)}kAAACwwCAAAk',
        '${_d(9)}kAkAACCCCAAkAk',
        '${_d(9)}kAkAACCYCAAkAk',
        '${_d(9)}kAkAACYCCAAkAk',
        '${_d(9)}kAkAAACCAAAkAk',
        '${_d(9)}kwkAAAAAAAAkwk',
        '${_d(9)}kkkAAAAAAAAkkk',
        '${_d(11)}kAAAAAAAAk',
        '${_d(12)}kLLkkLLk',
        '${_d(12)}kLLkkLLk',
        '${_d(12)}kLLkkLLk',
        '${_d(12)}kLLkkLLk',
        '${_d(12)}kLLkkLLk',
        '${_d(12)}kLLkkLLk',
        '${_d(12)}kLLkkLLk',
        '${_d(11)}kTTTkkTTTTk',
        '${_d(11)}kTTTkkTTTTk',
        '${_d(11)}kkkkkkkkkkk',
      ],
      [
        // Coat tails on both sides.
        for (var r = 22; r <= 24; r++) (r, 10, 'kA'),
        (25, 10, 'kk'),
        for (var r = 22; r <= 24; r++) (r, 20, 'Ak'),
        (25, 20, 'kk'),
        // Cane down to the ground, crackling at the top.
        for (var r = 17; r <= 31; r++) (r, 23, 'n'),
        (15, 23, 'Y'),
        (16, 23, 'Y'),
        (13, 22, 'y'),
        (14, 24, 'y'),
        (16, 25, 'y'),
      ],
    ),
    const {
      'k': Color(0xFF140F14),
      'H': Color(0xFFE6C46A),
      'S': Color(0xFFF0D2B4),
      'E': Color(0xFF3A5A8A),
      'm': Color(0xFFB07A60),
      'w': Color(0xFFF2EFE8),
      'A': Color(0xFF2E2834),
      'C': Color(0xFF7A1C2A),
      'Y': Color(0xFFFFD23F),
      'y': Color(0xFFFFF27A),
      'L': Color(0xFF1A161C),
      'T': Color(0xFF0E0C10),
      'n': Color(0xFF5A3A22),
    },
  ),
  'Riptide': PixelSprite(
    _put(
      [
        '',
        '',
        '',
        '${_d(13)}kkkkkk',
        '${_d(12)}kHHHHHHk',
        '${_d(11)}kHHHHHHHHk',
        '${_d(11)}kHHHHHHHHk',
        '${_d(11)}kHHMMMMMMk',
        '${_d(11)}kHMMMMMMMk',
        '${_d(11)}kHMMMMMMMk',
        '${_d(12)}kMMMMMMk',
        '${_d(13)}kMMMMk',
        '${_d(14)}kMMk',
        '${_d(11)}kkAAAAAAkk',
        '${_d(10)}kAAAAAAAAAAk',
        '${_d(9)}kBkACCACCAAkAk',
        '${_d(9)}kBkACCACCAAkAk',
        '${_d(9)}kBkAAAAAAAAkAk',
        '${_d(9)}kBkACCAACCAkAk',
        '${_d(9)}kSkBBBBBBBBkSk',
        '${_d(9)}kkkCCCCCCCCkkk',
        '${_d(12)}kLLLLLLk',
        '${_d(12)}kLLkkLLk',
        '${_d(12)}kLLkkLLk',
        '${_d(12)}kLLkkLLk',
        '${_d(12)}kCCkkCCk',
        '${_d(12)}kLLkkLLk',
        '${_d(12)}kLLkkLLk',
        '${_d(12)}kLLkkLLk',
        '${_d(11)}kTTTkkTTTTk',
        '${_d(11)}kTTTkkTTTTk',
        '${_d(11)}kkkkkkkkkkk',
      ],
      [
        // Night-vision goggles.
        (6, 18, 'kkk'),
        (7, 18, 'kEEEk'),
        (8, 18, 'kEEEk'),
        (9, 19, 'kkk'),
        // Rifle held across the body.
        (16, 20, 'kk'),
        (17, 10, 'kgggggggggggggggggggk'),
        (18, 10, 'kgk'),
        (18, 16, 'kGk'),
        (18, 20, 'kGGk'),
        (19, 20, 'kGGk'),
        (20, 21, 'kk'),
      ],
    ),
    const {
      'k': Color(0xFF0C1018),
      'H': Color(0xFF1F2C4A),
      'E': Color(0xFF4DFF7A),
      'M': Color(0xFF141A26),
      'A': Color(0xFF24365C),
      'B': Color(0xFF18243E),
      'C': Color(0xFF5A6474),
      'S': Color(0xFF18243E),
      'L': Color(0xFF24365C),
      'T': Color(0xFF0E1118),
      'g': Color(0xFF3A3E46),
      'G': Color(0xFF2A2D33),
    },
  ),
};

PixelSprite? spriteFor(String championName) => battleSprites[championName];
