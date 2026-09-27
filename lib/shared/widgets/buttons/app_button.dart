import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/di/injector.dart';
import '../../../core/security/biometric_service.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/extensions.dart';

/// Color role of [AppButton] — what the button is *about*, never how it is
/// filled. Every color the button paints derives from this, so a
/// [AppButtonVariant.danger] button is danger-colored whatever its type.
enum AppButtonVariant { primary, secondary, tertiary, danger }

/// Fill treatment of [AppButton] — how the [AppButtonVariant] color is applied.
///
/// - [filled]: solid variant background, contrasting label.
/// - [outlined]: transparent background, variant-colored border + label.
/// - [ghost]: transparent background, no border, variant-colored label.
///
/// Orthogonal to [AppButtonVariant] and [AppButtonShape]: any color combines
/// with any fill and any shape.
enum AppButtonType { filled, outlined, ghost }

/// Corner shape of [AppButton].
enum AppButtonShape { rounded, pill }

enum AppButtonSize { large, medium, small }

typedef _ButtonSizeConfig = ({
  double height,
  double fontSize,
  double iconSize,
  EdgeInsets padding,
});

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.variant,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.type = AppButtonType.filled,
    this.shape = AppButtonShape.rounded,
    this.prefixIcon,
    this.suffixIcon,
    this.width,
    this.size = AppButtonSize.medium,
    this.hint,
    this.requireAuth = false,
  });

  final AppButtonVariant variant;
  final String label;

  /// Tap handler. Null disables the button, same as [isDisabled].
  final VoidCallback? onPressed;

  /// When true, the label is replaced by a spinner and taps are ignored, while
  /// the button keeps its size so the surrounding layout doesn't jump.
  ///
  /// A loading button keeps its full color: it is busy, not unavailable. Only
  /// a disabled one fades.
  final bool isLoading;

  /// When true, the button is greyed out and ignores taps, whatever
  /// [onPressed] is.
  ///
  /// The same end state as `onPressed: null`, said the other way round:
  /// `isDisabled: !form.isValid` rather than
  /// `onPressed: form.isValid ? _submit : null`. Both work, and they compose —
  /// this one keeps the handler visible at the call site.
  final bool isDisabled;

  final AppButtonType type;
  final AppButtonShape shape;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final double? width;
  final AppButtonSize size;

  /// A line centered above the button — what the action will do, or what it
  /// costs, said before the user commits to it. Omit for a plain button.
  final String? hint;

  /// Runs biometric verification before [onPressed]; the press
  /// is cancelled when it fails.
  final bool requireAuth;

  _ButtonSizeConfig _getSizeConfig() => switch (size) {
        AppButtonSize.small => (
            height: AppConstants.touchTarget,
            fontSize: 14,
            iconSize: 18,
            padding: AppConstants.padding12,
          ),
        AppButtonSize.medium => (
            height: AppConstants.touchTarget + 4,
            fontSize: 16,
            iconSize: 22,
            padding: AppConstants.padding16,
          ),
        AppButtonSize.large => (
            height: AppConstants.touchTarget + 8,
            fontSize: 18,
            iconSize: 26,
            padding: AppConstants.padding16,
          ),
      };

  /// The variant's color, plus the color that reads on top of it. Single
  /// source for every color the button paints.
  (Color, Color) _colorsOf(ThemeData theme) => switch (variant) {
        AppButtonVariant.primary => (
            theme.colorScheme.primary,
            theme.colorScheme.onPrimary,
          ),
        AppButtonVariant.secondary => (
            theme.colorScheme.secondary,
            theme.colorScheme.onSecondary,
          ),
        AppButtonVariant.tertiary => (
            theme.colorScheme.tertiary,
            theme.colorScheme.onTertiary,
          ),
        AppButtonVariant.danger => (
            theme.colorScheme.error,
            theme.colorScheme.onError,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final sizeConfig = _getSizeConfig();
    final (accent, onAccent) = _colorsOf(theme);

    // Variant chooses the color; type only decides how that color is applied.
    final (backgroundColor, foregroundColor) = switch (type) {
      AppButtonType.filled => (accent, onAccent),
      AppButtonType.outlined || AppButtonType.ghost => (
          Colors.transparent,
          accent,
        ),
    };

    // Faded versions of the same colors for the disabled state, so a disabled
    // button still reads as its variant rather than a generic grey.
    final (disabledBackground, disabledForeground) = switch (type) {
      AppButtonType.filled => (
          accent.withValues(alpha: 0.35),
          onAccent.withValues(alpha: 0.9),
        ),
      AppButtonType.outlined || AppButtonType.ghost => (
          Colors.transparent,
          accent.withValues(alpha: 0.4),
        ),
    };

    // Busy is not the same as unavailable: a loading button keeps its full
    // color and only stops responding, while one that is actually disabled —
    // [isDisabled], or a null [onPressed] — fades, and stays faded even if it
    // is loading too.
    final showsBusy = isLoading && !isDisabled && onPressed != null;

    final button = SizedBox(
      width: width ?? double.infinity,
      height: sizeConfig.height,
      child: ElevatedButton(
        onPressed: isDisabled || isLoading || onPressed == null
            ? null
            : () async {
                HapticFeedback.selectionClick();
                if (!requireAuth) {
                  onPressed!();
                  return;
                }
                final verified = await getIt<BiometricService>()
                    .verifyUserLocalAuth(context);
                if (verified) onPressed!();
              },
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: sizeConfig.padding,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor:
              showsBusy ? backgroundColor : disabledBackground,
          disabledForegroundColor:
              showsBusy ? foregroundColor : disabledForeground,
          shape: RoundedRectangleBorder(
            borderRadius: switch (shape) {
              AppButtonShape.rounded => AppConstants.borderRadius12,
              AppButtonShape.pill => AppConstants.borderRadiusFull,
            },
            side: type == AppButtonType.outlined
                ? BorderSide(color: accent, width: 2)
                : BorderSide.none,
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: sizeConfig.iconSize,
                width: sizeConfig.iconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: foregroundColor,
                  // The spinner replaces the label on screen, not in the
                  // semantics tree: a loading button still names itself
                  // instead of announcing a bare "button".
                  semanticsLabel: label,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (prefixIcon != null) ...[
                    Icon(prefixIcon,
                        size: sizeConfig.iconSize, color: foregroundColor),
                    const SizedBox(width: AppConstants.space4),
                  ],
                  // Flexible + ellipsis so a label longer than an explicit
                  // [width] truncates instead of overflowing the button.
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: foregroundColor,
                        fontSize: sizeConfig.fontSize,
                      ),
                    ),
                  ),
                  if (suffixIcon != null) ...[
                    const SizedBox(width: AppConstants.space4),
                    Icon(suffixIcon,
                        size: sizeConfig.iconSize, color: foregroundColor),
                  ],
                ],
              ),
      ),
    );

    if (hint == null) return button;

    // Merged so the hint is read as part of the button, not as a stray
    // paragraph that happens to sit above one.
    return MergeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // Centered rather than stretched: stretch would hand the button a
        // tight width and override an explicit [width], so a 220px button
        // would come out full-bleed the moment it was given a hint.
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.space4),
            child: Text(
              hint!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          button,
        ],
      ),
    );
  }
}
