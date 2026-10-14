import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/battle_sprites.dart';
import '../data/champion_art.dart';
import '../theme/battle_colors.dart';

/// Draws a champion's battle sprite into a [boxSize] square: their artwork
/// from [battleSpriteImages] when it exists, otherwise their hand-drawn
/// [PixelSprite] grid (any grid size is scaled to fill the box). Both are
/// drawn with hard pixel edges. [flash] blends the sprite toward
/// [flashColor] (0 = none, 1 = solid), used for hit and cast flashes.
/// [knockedOut] lays the sprite on its back, dimmed.
class BattleSpriteView extends StatelessWidget {
  const BattleSpriteView({
    super.key,
    required this.championName,
    required this.boxSize,
    this.flipX = false,
    this.flash = 0,
    this.flashColor = Colors.white,
    this.knockedOut = false,
    this.pose = SpritePose.idle,
    this.poseProgress = 0,
  });

  final String championName;
  final double boxSize;
  final bool flipX;
  final double flash;
  final Color flashColor;
  final bool knockedOut;

  /// For animated sheets: which row to play, and how far through it
  /// (0 = first frame, 1 = last). Ignored by still sprites.
  final SpritePose pose;
  final double poseProgress;

  static const _koShade = Color(0xFF2A2630);

  @override
  Widget build(BuildContext context) {
    final sheet = spriteSheetFor(championName);
    if (sheet != null) return _buildSheet(sheet);

    final image = spriteImageFor(championName);
    final grid = spriteFor(championName);
    Widget painted;
    if (image != null) {
      painted = Image.asset(
        image,
        width: boxSize,
        height: boxSize,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        filterQuality: FilterQuality.none,
      );
      if (flash > 0) {
        painted = ColorFiltered(
          colorFilter: ColorFilter.mode(
            flashColor.withValues(alpha: flash.clamp(0, 1)),
            BlendMode.srcATop,
          ),
          child: painted,
        );
      }
      if (knockedOut) {
        painted = ColorFiltered(
          colorFilter: ColorFilter.mode(
            _koShade.withValues(alpha: 0.55),
            BlendMode.srcATop,
          ),
          child: painted,
        );
      }
      if (flipX) painted = Transform.flip(flipX: true, child: painted);
    } else if (grid != null) {
      painted = CustomPaint(
        size: Size.square(boxSize),
        painter: _PixelSpritePainter(
          sprite: grid,
          flipX: flipX,
          flash: flash,
          flashColor: flashColor,
          dim: knockedOut,
        ),
      );
    } else {
      final portrait = artFor(championName);
      if (portrait == null) return SizedBox.square(dimension: boxSize);
      painted = _portraitStandIn(portrait);
    }

    if (knockedOut) {
      painted = Transform.translate(
        offset: Offset(0, boxSize * 0.3),
        child: Transform.rotate(
          angle: flipX ? pi / 2 : -pi / 2,
          child: painted,
        ),
      );
    }
    return SizedBox.square(dimension: boxSize, child: painted);
  }

  /// Until a champion has a battle sprite, their card portrait stands in,
  /// in a small gold frame standing on the ground line.
  Widget _portraitStandIn(String portrait) {
    Widget framed = Container(
      width: boxSize * 0.62,
      height: boxSize * 0.82,
      decoration: BoxDecoration(
        border: Border.all(color: BattleColors.gold, width: 1.5),
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        portrait,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      ),
    );
    if (flash > 0) {
      framed = ColorFiltered(
        colorFilter: ColorFilter.mode(
          flashColor.withValues(alpha: (flash * 0.7).clamp(0, 1)),
          BlendMode.srcATop,
        ),
        child: framed,
      );
    }
    if (knockedOut) {
      framed = ColorFiltered(
        colorFilter: ColorFilter.mode(
          _koShade.withValues(alpha: 0.6),
          BlendMode.srcATop,
        ),
        child: framed,
      );
    }
    return SizedBox.square(
      dimension: boxSize,
      child: Align(alignment: Alignment.bottomCenter, child: framed),
    );
  }

  /// Shows one frame of an animated sheet: the whole sheet is scaled so a
  /// frame fills the box, then shifted so only the chosen frame shows. The
  /// sheet's own death row handles falling, so it is never rotated.
  Widget _buildSheet(SpriteSheet sheet) {
    final frame = (poseProgress.clamp(0.0, 1.0) * sheet.frames).floor().clamp(
      0,
      sheet.frames - 1,
    );
    Widget painted = _SheetFrame(
      sheet: sheet,
      column: frame,
      row: sheet.rowFor(pose),
      boxSize: boxSize,
    );
    if (flash > 0) {
      painted = ColorFiltered(
        colorFilter: ColorFilter.mode(
          flashColor.withValues(alpha: (flash * 0.6).clamp(0, 1)),
          BlendMode.srcATop,
        ),
        child: painted,
      );
    }
    // Mirror when the art faces the wrong way for this side of the field.
    if (flipX != sheet.facesLeft) {
      painted = Transform.flip(flipX: true, child: painted);
    }
    return SizedBox.square(dimension: boxSize, child: painted);
  }
}

/// Paints one frame of a sprite sheet with hard pixel edges. The sheet is
/// decoded once and shared by every fighter that uses it.
class _SheetFrame extends StatefulWidget {
  const _SheetFrame({
    required this.sheet,
    required this.column,
    required this.row,
    required this.boxSize,
  });

  final SpriteSheet sheet;
  final int column;
  final int row;
  final double boxSize;

  @override
  State<_SheetFrame> createState() => _SheetFrameState();
}

class _SheetFrameState extends State<_SheetFrame> {
  static final Map<String, ui.Image> _decoded = {};

  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(_SheetFrame old) {
    super.didUpdateWidget(old);
    if (old.sheet.asset != widget.sheet.asset) _resolve();
  }

  void _resolve() {
    final asset = widget.sheet.asset;
    if (_decoded.containsKey(asset)) return;
    _stopListening();
    final stream = AssetImage(asset)
        .resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener((info, _) {
      _decoded[asset] = info.image;
      if (mounted) setState(() {});
    });
    stream.addListener(listener);
    _stream = stream;
    _listener = listener;
  }

  void _stopListening() {
    final listener = _listener;
    if (listener != null) _stream?.removeListener(listener);
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _decoded[widget.sheet.asset];
    return CustomPaint(
      size: Size.square(widget.boxSize),
      painter: image == null
          ? null
          : _SheetFramePainter(
              image: image,
              frameSize: widget.sheet.frameSize,
              scale: widget.sheet.scale,
              column: widget.column,
              row: widget.row,
            ),
    );
  }
}

class _SheetFramePainter extends CustomPainter {
  _SheetFramePainter({
    required this.image,
    required this.frameSize,
    required this.scale,
    required this.column,
    required this.row,
  });

  final ui.Image image;
  final int frameSize;
  final double scale;
  final int column;
  final int row;

  @override
  void paint(Canvas canvas, Size size) {
    final f = frameSize.toDouble();
    final w = size.width * scale, h = size.height * scale;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(column * f, row * f, f, f),
      Rect.fromLTWH((size.width - w) / 2, size.height - h, w, h),
      Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false,
    );
  }

  @override
  bool shouldRepaint(_SheetFramePainter old) =>
      old.image != image ||
      old.column != column ||
      old.row != row ||
      old.scale != scale;
}

class _PixelSpritePainter extends CustomPainter {
  _PixelSpritePainter({
    required this.sprite,
    required this.flipX,
    required this.flash,
    required this.flashColor,
    required this.dim,
  });

  final PixelSprite sprite;
  final bool flipX;
  final double flash;
  final Color flashColor;
  final bool dim;

  @override
  void paint(Canvas canvas, Size size) {
    final n = sprite.size;
    final px = size.width / n;
    final rows = sprite.rows;
    final top = n - rows.length;
    final paint = Paint()..isAntiAlias = false;
    for (var r = 0; r < rows.length; r++) {
      final row = rows[r];
      for (var c = 0; c < row.length && c < n; c++) {
        final color = sprite.palette[row[c]];
        if (color == null) continue;
        var drawn = Color.lerp(color, flashColor, flash.clamp(0, 1))!;
        if (dim) {
          drawn = Color.lerp(drawn, BattleSpriteView._koShade, 0.55)!;
        }
        paint.color = drawn;
        final x = flipX ? n - 1 - c : c;
        // A hair of overlap hides seams between pixels at fractional scales.
        canvas.drawRect(
          Rect.fromLTWH(x * px, (top + r) * px, px + 0.5, px + 0.5),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PixelSpritePainter old) =>
      old.sprite != sprite ||
      old.flipX != flipX ||
      old.flash != flash ||
      old.flashColor != flashColor ||
      old.dim != dim;
}
