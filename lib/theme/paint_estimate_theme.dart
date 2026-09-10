import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Gwinn Painting Solutions brand palette and decoration tokens.
abstract final class PaintEstimateTheme {
  static const Color background = Color(0xFFF4F6F9);
  static const Color midnightNavy = Color(0xFF0D2534);
  static const Color warmGold = Color(0xFFD4AF67);
  static const Color charcoal = Color(0xFF1E262C);
  static const Color white = Color(0xFFFFFFFF);

  static const double cardRadius = 12;
  static const double cardElevation = 2;

  static BoxDecoration cardDecoration({Color? backgroundColor}) {
    return BoxDecoration(
      color: backgroundColor ?? white,
      borderRadius: BorderRadius.circular(cardRadius),
      boxShadow: [
        BoxShadow(
          color: midnightNavy.withValues(alpha: 0.08),
          offset: const Offset(0, 2),
          blurRadius: 8,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: midnightNavy.withValues(alpha: 0.04),
          offset: const Offset(0, 1),
          blurRadius: 3,
        ),
      ],
    );
  }

  static BoxDecoration navyHeaderDecoration() {
    return const BoxDecoration(
      color: midnightNavy,
      borderRadius: BorderRadius.vertical(top: Radius.circular(cardRadius)),
    );
  }

  static TextStyle brandTitleStyle({double size = 28}) {
    return GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: FontWeight.w800,
      letterSpacing: 6,
      color: warmGold,
      height: 1.1,
    );
  }

  static TextStyle brandSubtitleStyle({double size = 11}) {
    return GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: FontWeight.w500,
      letterSpacing: 3.2,
      color: white,
      height: 1.2,
    );
  }

  static TextStyle titleStyle({double size = 18, Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: color ?? charcoal,
    );
  }

  static TextStyle bodyStyle({double size = 14, Color? color, FontWeight? weight}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight ?? FontWeight.w500,
      color: color ?? charcoal,
    );
  }

  static TextStyle monoStyle({
    double size = 14,
    Color? color,
    FontWeight weight = FontWeight.w600,
  }) {
    return GoogleFonts.spaceMono(
      fontSize: size,
      fontWeight: weight,
      color: color ?? charcoal,
    );
  }
}
