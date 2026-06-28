import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography scale for Kitchen Key — "Premium Editorial".
///
/// Headlines use the elegant **Fraunces** serif (magazine display face) while
/// body and UI copy use **Inter** for crisp readability. The mix gives the app
/// a refined, editorial character.
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(Color primary, Color secondary) {
    final display = GoogleFonts.fraunces(color: primary);
    final body = GoogleFonts.inter(color: primary);

    return TextTheme(
      // Serif display faces
      displayLarge: display.copyWith(
          fontSize: 40, fontWeight: FontWeight.w600, height: 1.05, letterSpacing: -0.5),
      displayMedium: display.copyWith(
          fontSize: 32, fontWeight: FontWeight.w600, height: 1.1, letterSpacing: -0.4),
      displaySmall: display.copyWith(
          fontSize: 27, fontWeight: FontWeight.w600, height: 1.15, letterSpacing: -0.3),
      headlineMedium: display.copyWith(
          fontSize: 24, fontWeight: FontWeight.w600, height: 1.2),
      headlineSmall: display.copyWith(
          fontSize: 21, fontWeight: FontWeight.w600, height: 1.25),
      titleLarge: display.copyWith(
          fontSize: 19, fontWeight: FontWeight.w600, height: 1.3),
      // Sans UI faces
      titleMedium: body.copyWith(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3),
      titleSmall: body.copyWith(fontSize: 14, fontWeight: FontWeight.w600, height: 1.3),
      bodyLarge: body.copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 1.55),
      bodyMedium: body.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.55, color: secondary),
      bodySmall: body.copyWith(fontSize: 12.5, fontWeight: FontWeight.w400, height: 1.45, color: secondary),
      labelLarge: body.copyWith(fontSize: 14, fontWeight: FontWeight.w600, height: 1.2),
      labelMedium: body.copyWith(fontSize: 12, fontWeight: FontWeight.w600, height: 1.2),
      // Eyebrow / uppercase tag label
      labelSmall: body.copyWith(
          fontSize: 11, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: 1.5),
    );
  }

  /// Convenience: an uppercase, letter-spaced "eyebrow" style for section
  /// labels above editorial titles.
  static TextStyle eyebrow(BuildContext context, {Color? color}) {
    return Theme.of(context).textTheme.labelSmall!.copyWith(
          color: color,
          letterSpacing: 1.6,
        );
  }
}
