import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'battle_colors.dart';

/// Bold, bright body text in GFS Neohellenic (a Greek-style face), distinct
/// from the Cinzel headings.
TextStyle bodyStyle({
  double fontSize = 12,
  Color color = BattleColors.cream,
  FontWeight fontWeight = FontWeight.w700,
  double? letterSpacing,
  double? height,
  FontStyle? fontStyle,
}) => GoogleFonts.gfsNeohellenic(
  fontSize: fontSize,
  color: color,
  fontWeight: fontWeight,
  letterSpacing: letterSpacing,
  height: height,
  fontStyle: fontStyle,
);
