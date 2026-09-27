import 'package:flutter/material.dart';

abstract final class AppConstants {
  // ── Brand palette ─────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF92886F);
  static const Color secondary = Color(0xFF000000);
  static const Color tertiary = Color(0xFF000000);
  static const Color surface = Color(0xFFf9f9f9);
  static const Color onSurface = Color(0xFF000000);
  static const Color outline = Color(0xFF000000);
  static const Color error = Color(0xFFba1a1a);

  // ── Surface layers ────────────────────────────────────────────────────────
  static const Color surfaceContainerLowest = Color(0xFF000000);
  static const Color surfaceContainerLow = Color(0xFF000000);
  static const Color surfaceContainerHighest = Color(0xFF000000);

  // ── Status colors ─────────────────────────────────────────────────────────
  // Kept out of the palette so they read the same whatever the brand becomes.
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFED6C02);
  static const Color info = Color(0xFF0288D1);

  // ── Type ──────────────────────────────────────────────────────────────────
  // Null uses the platform default. Declare a font under `flutter: fonts:` in
  // pubspec.yaml and name it here, or add google_fonts and swap AppTheme's
  // textTheme for GoogleFonts.interTextTheme(...).
  static const String? fontFamily = null;

  // ── Avatar background fallbacks ───────────────────────────────────────────
  static const List<Color> avatarPalette = [
    Color(0xFFEF5350),
    Color(0xFFAB47BC),
    Color(0xFF5C6BC0),
    Color(0xFF29B6F6),
    Color(0xFF26A69A),
    Color(0xFF9CCC65),
    Color(0xFFFFCA28),
    Color(0xFFFF7043),
    Color(0xFF8D6E63),
    Color(0xFF78909C),
  ];

  // ── Spacing — 4pt grid ────────────────────────────────────────────────────
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space48 = 48;

  // ── Padding helpers ───────────────────────────────────────────────────────
  static const padding4 = EdgeInsets.all(space4);
  static const padding12 = EdgeInsets.all(space12);
  static const padding16 = EdgeInsets.all(space16);
  static const padding24 = EdgeInsets.all(space24);

  static const paddingV8 = EdgeInsets.symmetric(vertical: space8);

  static const paddingPage = EdgeInsets.symmetric(
    horizontal: space12,
    vertical: space12,
  );

  // ── Icon sizes ────────────────────────────────────────────────────────────
  static const double iconSmall = 16;
  static const double iconMedium = 24;
  static const double iconLarge = 32;

  // ── Text sizes — Material type scale / iOS HIG ────────────────────────────
  static const double fontSize11 = 11; // caption2 / label small
  static const double fontSize12 = 12; // caption1 / body small
  static const double fontSize13 = 13; // footnote
  static const double fontSize14 = 14; // label / body medium (Material)
  static const double fontSize15 = 15; // subheadline
  static const double fontSize16 = 16; // callout / body large
  static const double fontSize17 = 17; // body / headline (iOS default)
  static const double fontSize20 = 20; // title3
  static const double fontSize22 = 22; // title2 / titleL
  static const double fontSize28 = 28; // title1 / headlineM
  static const double fontSize34 = 34; // largeTitle (iOS)

  // ── Touch targets — iOS HIG 44pt minimum, Material 48dp ───────────────────
  static const double touchTarget = 48;

  // ── Border radius — Material medium = 12, iOS cards ≈ 10–13 ──────────────
  static const double radius4 = 4;
  static const double radius8 = 8;
  static const double radius12 = 12; // Material medium / iOS card
  static const double radius16 = 16; // Material large
  static const double radius24 = 24; // bottom sheets, large cards
  static const double radiusFull = 999; // pills / chips

  static final borderRadius4 = BorderRadius.circular(radius4);
  static final borderRadius8 = BorderRadius.circular(radius8);
  static final borderRadius12 = BorderRadius.circular(radius12);
  static final borderRadius16 = BorderRadius.circular(radius16);
  static final borderRadiusFull = BorderRadius.circular(radiusFull);

  // ── Animation durations ───────────────────────────────────────────────────
  static const Duration duration200 = Duration(milliseconds: 200);
  static const Duration duration300 = Duration(milliseconds: 300);
  static const Duration duration500 = Duration(milliseconds: 500);

  // ── Motion curves ─────────────────────────────────────────────────────────
  // Standard for anything that moves within the screen — a page, a fade.
  // Enter decelerates into place and exit accelerates away, so an arrival
  // settles quickly and a departure does not linger.
  static const Curve curveStandard = Curves.easeInOut;
  static const Curve curveEnter = Curves.easeOutCubic;
  static const Curve curveExit = Curves.easeInCubic;
}
