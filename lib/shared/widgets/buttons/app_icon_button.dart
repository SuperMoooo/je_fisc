import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/extensions.dart';

/// Color role of [AppIconButton]. Mirrors [AppButtonVariant] and
/// [AppLeadingIconVariant] so every control speaks the same color vocabulary.
enum AppIconButtonVariant { primary, secondary, tertiary, danger }

/// Fill treatment of [AppIconButton] — how the variant color is applied.
///
/// - [filled]: solid variant background, contrasting icon.
/// - [tonal]: soft variant-tinted background, variant-colored icon.
/// - [outlined]: transparent background, variant-colored border + icon.
/// - [ghost]: no container at all — just the variant-colored icon.
enum AppIconButtonType { filled, tonal, outlined, ghost }

/// Corner shape of the tap target.
enum AppIconButtonShape { rounded, circle }

enum AppIconButtonSize { small, medium, large }

typedef _IconButtonSizeConfig = ({double container, double icon});

/// A tappable icon — [AppLeadingIcon]'s interactive sibling. Same color
/// vocabulary, but with a ripple, haptics, a loading state and a real touch
/// target. Use [AppLeadingIcon] when the icon is decoration, this when it does
/// something.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.variant = AppIconButtonVariant.primary,
    this.type = AppIconButtonType.ghost,
    this.shape = AppIconButtonShape.circle,
    this.size = AppIconButtonSize.medium,
    this.tooltip,
    this.semanticLabel,
    this.isLoading = false,
    this.color,
  });

  final IconData icon;

  /// Tap handler. Pass null to render the button in its disabled state.
  final VoidCallback? onPressed;
  final AppIconButtonVariant variant;
  final AppIconButtonType type;
  final AppIconButtonShape shape;
  final AppIconButtonSize size;

  /// Long-press label. Worth setting on every icon button — an icon on its own
  /// rarely names itself, and it is what a screen reader reads when
  /// [semanticLabel] is not given.
  final String? tooltip;

  /// What a screen reader announces. Defaults to [tooltip], so setting that
  /// alone is enough; give this one only when the spoken name should differ
  /// from the one on screen.
  final String? semanticLabel;

  /// Replaces the icon with a spinner and ignores taps, keeping the same size
  /// so the surrounding layout doesn't jump.
  final bool isLoading;

  /// Overrides [variant]'s accent color. For the control that has to match a
  /// color the variant vocabulary doesn't name — a status tint, say. Reach for
  /// a [variant] first; this is the escape hatch.
  final Color? color;

  static const double _tonalFillOpacity = 0.12;
  static const double _outlinedBorderWidth = 1.5;
  static const double _disabledOpacity = 0.38;

  /// The painted dimension for [size] — the colored circle or rounded square
  /// the eye sees, which at [AppIconButtonSize.small] is deliberately smaller
  /// than what a finger can hit. See [tapTargetOf].
  static double dimensionOf(AppIconButtonSize size) => switch (size) {
    AppIconButtonSize.small => 32.0,
    AppIconButtonSize.medium => AppConstants.touchTarget,
    AppIconButtonSize.large => AppConstants.touchTarget + 16,
  };

  /// The space the button actually occupies: [dimensionOf], or Material's
  /// minimum touch target when the painted shape is smaller than that. Public
  /// so a layout reserving room for the button — an AppBar's leading slot,
  /// say — measures it rather than guessing at it.
  static double tapTargetOf(AppIconButtonSize size) {
    final painted = dimensionOf(size);
    return painted < AppConstants.touchTarget
        ? AppConstants.touchTarget
        : painted;
  }

  _IconButtonSizeConfig _sizeConfig() => (
    container: dimensionOf(size),
    icon: switch (size) {
      AppIconButtonSize.small => AppConstants.iconSmall,
      AppIconButtonSize.medium => AppConstants.iconMedium,
      AppIconButtonSize.large => AppConstants.iconLarge,
    },
  );

  /// The accent color, plus the color that reads on top of it.
  (Color, Color) _colorsOf(ThemeData theme) {
    final override = color;
    if (override != null) {
      // No colorScheme pair exists for an arbitrary color, so pick whichever
      // of black/white keeps the filled treatment legible.
      return (
        override,
        ThemeData.estimateBrightnessForColor(override) == Brightness.dark
            ? Colors.white
            : Colors.black,
      );
    }
    return switch (variant) {
      AppIconButtonVariant.primary => (
        theme.colorScheme.primary,
        theme.colorScheme.onPrimary,
      ),
      AppIconButtonVariant.secondary => (
        theme.colorScheme.secondary,
        theme.colorScheme.onSecondary,
      ),
      AppIconButtonVariant.tertiary => (
        theme.colorScheme.tertiary,
        theme.colorScheme.onTertiary,
      ),
      AppIconButtonVariant.danger => (
        theme.colorScheme.error,
        theme.colorScheme.onError,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final sizeConfig = _sizeConfig();
    final (accent, onAccent) = _colorsOf(theme);
    final enabled = onPressed != null && !isLoading;

    // Variant chooses the color; type only decides how that color is applied.
    final (backgroundColor, foregroundColor) = switch (type) {
      AppIconButtonType.filled => (accent, onAccent),
      AppIconButtonType.tonal => (
        Color.alphaBlend(
          accent.withValues(alpha: _tonalFillOpacity),
          theme.colorScheme.surface,
        ),
        accent,
      ),
      AppIconButtonType.outlined ||
      AppIconButtonType.ghost => (Colors.transparent, accent),
    };

    // A disabled button stays its variant, just faded — never a generic grey.
    final resolvedForeground = enabled
        ? foregroundColor
        : foregroundColor.withValues(alpha: _disabledOpacity);
    final resolvedBackground = enabled
        ? backgroundColor
        : backgroundColor.withValues(alpha: _disabledOpacity);

    final border = type == AppIconButtonType.outlined
        ? BorderSide(color: resolvedForeground, width: _outlinedBorderWidth)
        : BorderSide.none;

    // An icon names nothing on its own, so whatever the caller gave becomes
    // the spoken name. With neither, the button is still marked as one — that
    // at least announces it is pressable rather than reading as decoration.
    final label = semanticLabel ?? tooltip;

    final VoidCallback? handleTap = enabled
        ? () {
            HapticFeedback.selectionClick();
            onPressed!();
          }
        : null;

    final painted = Material(
      color: resolvedBackground,
      clipBehavior: Clip.antiAlias,
      shape: shape == AppIconButtonShape.circle
          ? CircleBorder(side: border)
          : RoundedRectangleBorder(
              borderRadius: AppConstants.borderRadius12,
              side: border,
            ),
      child: InkWell(
        onTap: handleTap,
        child: SizedBox.square(
          dimension: sizeConfig.container,
          child: isLoading
              ? Center(
                  child: SizedBox.square(
                    dimension: sizeConfig.icon,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: resolvedForeground,
                    ),
                  ),
                )
              : Icon(icon, size: sizeConfig.icon, color: resolvedForeground),
        ),
      ),
    );

    // Tooltip carries semantics of its own; the Semantics below already says
    // the name, so excluding it here keeps it from being read twice.
    final tooltipped = tooltip == null
        ? painted
        : Tooltip(
            message: tooltip!,
            excludeFromSemantics: true,
            child: painted,
          );

    final target = tapTargetOf(size);

    // Below Material's minimum, the shape stays the size it is drawn and only
    // the area a finger can hit grows — transparent slop around the paint,
    // the same trick MaterialTapTargetSize.padded plays. A tap landing on the
    // shape is taken by the InkWell (the innermost tap recognizer wins the
    // arena), one further out by this; either way the callback fires once.
    final sized = target == sizeConfig.container
        ? tooltipped
        : SizedBox.square(
            dimension: target,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: handleTap,
              child: Center(child: tooltipped),
            ),
          );

    // Outermost, so the node a screen reader finds covers the whole target
    // rather than only the part of it that is painted.
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: sized,
    );
  }
}
