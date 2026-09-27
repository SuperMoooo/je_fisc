import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import 'app_status_colors.dart';

abstract final class AppTheme {
  static const String? _fontFamily = AppConstants.fontFamily;

  // Colors are left null on purpose, so each style inherits the right
  // on-surface color for the current brightness.
  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(fontFamily: _fontFamily, fontSize: 57, height: 1.12, fontWeight: FontWeight.w400, letterSpacing: -0.25),
    displayMedium: TextStyle(fontFamily: _fontFamily, fontSize: 45, height: 1.16, fontWeight: FontWeight.w400),
    displaySmall: TextStyle(fontFamily: _fontFamily, fontSize: 36, height: 1.22, fontWeight: FontWeight.w400),
    headlineLarge: TextStyle(fontFamily: _fontFamily, fontSize: AppConstants.fontSize28 + 4, height: 1.25, fontWeight: FontWeight.w600),
    headlineMedium: TextStyle(fontFamily: _fontFamily, fontSize: AppConstants.fontSize28, height: 1.29, fontWeight: FontWeight.w600),
    headlineSmall: TextStyle(fontFamily: _fontFamily, fontSize: 24, height: 1.33, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(fontFamily: _fontFamily, fontSize: AppConstants.fontSize22, height: 1.27, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontFamily: _fontFamily, fontSize: AppConstants.fontSize16, height: 1.50, fontWeight: FontWeight.w600, letterSpacing: 0.15),
    titleSmall: TextStyle(fontFamily: _fontFamily, fontSize: AppConstants.fontSize14, height: 1.43, fontWeight: FontWeight.w600, letterSpacing: 0.1),
    bodyLarge: TextStyle(fontFamily: _fontFamily, fontSize: AppConstants.fontSize16, height: 1.50, fontWeight: FontWeight.w400, letterSpacing: 0.5),
    bodyMedium: TextStyle(fontFamily: _fontFamily, fontSize: AppConstants.fontSize14, height: 1.43, fontWeight: FontWeight.w400, letterSpacing: 0.25),
    bodySmall: TextStyle(fontFamily: _fontFamily, fontSize: AppConstants.fontSize12, height: 1.33, fontWeight: FontWeight.w400, letterSpacing: 0.4),
    labelLarge: TextStyle(fontFamily: _fontFamily, fontSize: AppConstants.fontSize14, height: 1.43, fontWeight: FontWeight.w600, letterSpacing: 0.1),
    labelMedium: TextStyle(fontFamily: _fontFamily, fontSize: AppConstants.fontSize12, height: 1.33, fontWeight: FontWeight.w600, letterSpacing: 0.5),
    labelSmall: TextStyle(fontFamily: _fontFamily, fontSize: AppConstants.fontSize11, height: 1.45, fontWeight: FontWeight.w600, letterSpacing: 0.5),
  );

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    extensions: const [AppStatusColors.light],
    textTheme: _textTheme,
    fontFamily: AppConstants.fontFamily,
    colorScheme: ColorScheme.light(
      primary: AppConstants.primary,
      onPrimary: AppConstants.surface,

      secondary: AppConstants.secondary,
      onSecondary: AppConstants.surface,

      tertiary: AppConstants.tertiary,
      onTertiary: AppConstants.surface,

      surface: AppConstants.surface,
      onSurface: AppConstants.onSurface,
      surfaceContainer: AppConstants.surfaceContainerLow,
      surfaceContainerLow: AppConstants.surfaceContainerLow,
      surfaceContainerLowest: AppConstants.surfaceContainerLowest,
      surfaceContainerHigh: AppConstants.surfaceContainerHighest,
      surfaceContainerHighest: AppConstants.surfaceContainerHighest,
      error: AppConstants.error,
      onError: AppConstants.surface,

      outline: AppConstants.outline.withValues(alpha: 0.3),
      outlineVariant: AppConstants.outline.withValues(alpha: 0.3),
    ),

    scaffoldBackgroundColor: AppConstants.surface,

    iconTheme: const IconThemeData(
      color: AppConstants.outline,
      size: AppConstants.iconSmall,
    ),

    searchBarTheme: SearchBarThemeData(
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: const WidgetStatePropertyAll(
        AppConstants.surfaceContainerLowest,
      ),
      surfaceTintColor: const WidgetStatePropertyAll(
        AppConstants.surfaceContainerLowest,
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: AppConstants.borderRadius12),
      ),
      side: const WidgetStatePropertyAll(BorderSide.none),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: AppConstants.space12,
          vertical: (AppConstants.touchTarget - AppConstants.fontSize16) / 2,
        ),
      ),
      textStyle: WidgetStatePropertyAll(
        _textTheme.bodyLarge?.copyWith(color: AppConstants.onSurface),
      ),
      hintStyle: WidgetStatePropertyAll(
        _textTheme.bodyLarge?.copyWith(
          color: AppConstants.onSurface.withValues(alpha: 0.35),
        ),
      ),
    ),

    // AppAppBar passes no color of its own, so this is the bar the app wears.
    appBarTheme: const AppBarTheme(
      backgroundColor: AppConstants.surface,
      foregroundColor: AppConstants.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),

    // AppCard reads this — color, corner radius and shadow — so changing a
    // card anywhere in the app is a change here.
    cardTheme: CardThemeData(
      color: AppConstants.surfaceContainerLowest,
      shadowColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: AppConstants.borderRadius16),
    ),
    // AppBottomNav reads both. The indicator is a tint rather than a flat
    // fill: the icon and its label sit on top of it and have to stay readable.
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppConstants.surface,
      indicatorColor: AppConstants.primary.withValues(alpha: 0.12),
    ),

    tabBarTheme: TabBarThemeData(
      indicatorColor: AppConstants.primary,
      tabAlignment: TabAlignment.fill,
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorAnimation: TabIndicatorAnimation.elastic,
      labelColor: AppConstants.onSurface,
      labelStyle: _textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
      unselectedLabelColor: AppConstants.onSurface.withValues(alpha: 0.5),
      unselectedLabelStyle: _textTheme.labelLarge,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppConstants.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: AppConstants.borderRadius12,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppConstants.borderRadius12,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppConstants.borderRadius12,
        borderSide: const BorderSide(color: AppConstants.outline, width: 0.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppConstants.borderRadius12,
        borderSide: const BorderSide(color: AppConstants.error, width: 0.5),
      ),
      prefixIconColor: AppConstants.primary,
      suffixIconColor: AppConstants.primary,
      contentPadding: const EdgeInsets.symmetric(
        vertical: (AppConstants.touchTarget - AppConstants.fontSize16) / 2,
        horizontal: AppConstants.space12,
      ),

      hintStyle: _textTheme.bodyLarge?.copyWith(
        color: AppConstants.onSurface.withValues(alpha: 0.35),
      ),
    ),

    datePickerTheme: DatePickerThemeData(
      backgroundColor: AppConstants.surface,
      headerBackgroundColor: AppConstants.primary,
      headerForegroundColor: AppConstants.surface,
      rangePickerBackgroundColor: AppConstants.surface,
      rangePickerHeaderBackgroundColor: AppConstants.primary,
      rangePickerHeaderForegroundColor: AppConstants.surface,
      shape: RoundedRectangleBorder(borderRadius: AppConstants.borderRadius12),
    ),

    timePickerTheme: TimePickerThemeData(
      backgroundColor: AppConstants.surface,
      shape: RoundedRectangleBorder(borderRadius: AppConstants.borderRadius12),
      dialBackgroundColor: AppConstants.surfaceContainerLowest,
      dialHandColor: AppConstants.primary,
      hourMinuteColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppConstants.primary; // Color when selected
        }
        return AppConstants.secondary.withValues(
          alpha: 0.2,
        ); // Color when not selected
      }),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.selected)) {
          return AppConstants.primary;
        }
        return Colors.transparent;
      }),
      checkColor: const WidgetStatePropertyAll(AppConstants.surface),
      shape: RoundedRectangleBorder(borderRadius: AppConstants.borderRadius4),
      side: const BorderSide(color: AppConstants.primary, width: 1),
    ),

    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppConstants.primary,
      selectionColor: AppConstants.primary.withValues(alpha: 0.25),
      selectionHandleColor: AppConstants.primary,
    ),

    dividerTheme: const DividerThemeData(color: Colors.transparent),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppConstants.primary,
      foregroundColor: Colors.white,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppConstants.surface,
      shape: RoundedRectangleBorder(borderRadius: AppConstants.borderRadius12),
    ),

    // AppChoiceChip and the multi-select's chips read this, so a chip's fill
    // and its corners are set here rather than on each widget.
    chipTheme: ChipThemeData(
      backgroundColor: AppConstants.surfaceContainerLow,
      selectedColor: AppConstants.primary.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: AppConstants.borderRadiusFull,
      ),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppConstants.surface
            : AppConstants.outline,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppConstants.primary
            : AppConstants.surfaceContainerHighest,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),

    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppConstants.primary
            : AppConstants.outline,
      ),
    ),

    sliderTheme: SliderThemeData(
      activeTrackColor: AppConstants.primary,
      inactiveTrackColor: AppConstants.primary.withValues(alpha: 0.15),
      thumbColor: AppConstants.primary,
      overlayColor: AppConstants.primary.withValues(alpha: 0.12),
      trackHeight: 4,
    ),

    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: AppConstants.primary,
      linearTrackColor: AppConstants.primary.withValues(alpha: 0.15),
      linearMinHeight: 6,
    ),

    // AppListTile is a hand-built row rather than a Material ListTile, but it
    // reads this too, so both kinds of row keep the same inset.
    listTileTheme: const ListTileThemeData(
      iconColor: AppConstants.onSurface,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppConstants.space12,
        vertical: AppConstants.space12,
      ),
    ),

    badgeTheme: const BadgeThemeData(
      backgroundColor: AppConstants.error,
      textColor: AppConstants.surface,
    ),

    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        side: const WidgetStatePropertyAll(BorderSide.none),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppConstants.primary
              : AppConstants.surfaceContainerLowest,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppConstants.surface
              : AppConstants.onSurface,
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AppConstants.borderRadius8),
        ),
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppConstants.surfaceContainerHighest,
      contentTextStyle: _textTheme.bodyMedium?.copyWith(
        color: AppConstants.onSurface,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppConstants.borderRadius12),
      insetPadding: AppConstants.padding16,
      elevation: 0,
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
  );
}
