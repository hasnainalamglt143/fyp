import 'package:flutter/material.dart';

/// Central color palette for Kitchen Key — "Premium Editorial".
///
/// A refined, magazine-like scheme: a deep herb green primary, warm cream
/// canvas, charcoal ink text and a muted saffron accent. Soft shadows replace
/// hard borders to feel high-end rather than flat.
class AppColors {
  AppColors._();

  // ---- Brand ----
  static const Color primary = Color(0xFF1B6B4C); // deep herb green
  static const Color primaryDark = Color(0xFF11543A);
  static const Color primaryLight = Color(0xFF4FA37C);
  static const Color primarySurface = Color(0xFFE7F1EA); // tinted chip bg

  static const Color accent = Color(0xFFE0922F); // muted saffron
  static const Color accentDark = Color(0xFFB6741D);
  static const Color accentSurface = Color(0xFFFAEEDC);

  static const Color coral = Color(0xFFE56B5A); // for "save"/heart highlights

  // ---- Neutrals (light) ----
  static const Color background = Color(0xFFFBF8F2); // warm cream canvas
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF1ECE2);
  static const Color border = Color(0xFFEAE3D6);

  static const Color textPrimary = Color(0xFF1A1A17); // charcoal ink
  static const Color textSecondary = Color(0xFF6A655C);
  static const Color textTertiary = Color(0xFF9C958A);

  // ---- Neutrals (dark) ----
  static const Color backgroundDark = Color(0xFF14150F);
  static const Color surfaceDark = Color(0xFF1E201A);
  static const Color surfaceAltDark = Color(0xFF282A22);
  static const Color borderDark = Color(0xFF383A30);

  static const Color textPrimaryDark = Color(0xFFF5F1E8);
  static const Color textSecondaryDark = Color(0xFFB9B3A6);
  static const Color textTertiaryDark = Color(0xFF837D71);

  // ---- Semantic ----
  static const Color success = Color(0xFF2BA84A);
  static const Color warning = Color(0xFFE0922F);
  static const Color error = Color(0xFFD64545);
  static const Color rating = Color(0xFFE8A317); // star colour

  // ---- Gradients ----
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF227B59), Color(0xFF11543A)],
  );

  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEBA94B), Color(0xFFE0922F)],
  );

  /// Soft scrim used on top of food imagery so white text stays legible.
  static const LinearGradient imageScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0x05000000), Color(0xD9000000)],
    stops: [0.35, 0.55, 1.0],
  );

  // ---- Soft shadows ----
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: const Color(0xFF1A1A17).withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF1A1A17).withValues(alpha: 0.05),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];
}
