import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

/// The status colors — success, warning, info — as part of the theme.
///
/// `colorScheme` already carries `error`; these are the three Material has no
/// slot for. Registered on each `ThemeData` in `app_theme.dart`, so a widget
/// reads `context.statusColors.success` and gets the right value for the
/// current brightness without asking which one it is:
///
/// ```dart
/// final color = context.statusColors.warning;
/// ```
///
/// The values themselves live in `AppConstants` with the rest of the palette —
/// change them there.
@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors({
    required this.success,
    required this.warning,
    required this.info,
  });

  /// The set `AppTheme.light` registers — and what [of] falls back to under a
  /// theme that registers none.
  static const light = AppStatusColors(
    success: AppConstants.success,
    warning: AppConstants.warning,
    info: AppConstants.info,
  );

  final Color success;
  final Color warning;
  final Color info;

  /// [theme]'s status colors, or [light] when it registers none — a
  /// `ThemeData` built by hand, or a widget test — so a read never throws.
  static AppStatusColors of(ThemeData theme) =>
      theme.extension<AppStatusColors>() ?? light;

  @override
  AppStatusColors copyWith({Color? success, Color? warning, Color? info}) =>
      AppStatusColors(
        success: success ?? this.success,
        warning: warning ?? this.warning,
        info: info ?? this.info,
      );

  /// What `AnimatedTheme` calls while the app crossfades between light and
  /// dark, so the status colors fade with everything else.
  @override
  AppStatusColors lerp(AppStatusColors? other, double t) {
    if (other is! AppStatusColors) return this;
    return AppStatusColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}

extension StatusColorsX on BuildContext {
  /// The current theme's [AppStatusColors] — see [AppStatusColors.of].
  AppStatusColors get statusColors => AppStatusColors.of(Theme.of(this));
}
