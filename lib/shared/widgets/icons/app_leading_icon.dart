import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/extensions.dart';

/// Color role of [AppLeadingIcon]. Mirrors [AppButtonVariant] so a leading
/// icon, a button and an input all speak the same color vocabulary.
enum AppLeadingIconVariant { primary, secondary, tertiary, danger }

/// Fill treatment of [AppLeadingIcon] — how the [AppLeadingIconVariant] color
/// is applied to the container.
///
/// - [filled]: solid variant background, contrasting icon.
/// - [tonal]: soft variant-tinted background, variant-colored icon.
/// - [outlined]: transparent background, variant-colored border + icon.
/// - [plain]: no container at all — just the variant-colored icon.
enum AppLeadingIconType { filled, tonal, outlined, plain }

/// Corner shape of the container.
enum AppLeadingIconShape { rounded, circle }

enum AppLeadingIconSize { small, medium, large }

typedef _LeadingIconSizeConfig = ({double container, double icon});

/// A Material-style icon container: a colored, rounded (or circular) box
/// with a single icon centered in it. Meant as a leading visual for list
/// tiles, cards and dialogs — not a tappable control on its own.
class AppLeadingIcon extends StatelessWidget {
  const AppLeadingIcon({
    super.key,
    required this.icon,
    this.variant = AppLeadingIconVariant.primary,
    this.type = AppLeadingIconType.tonal,
    this.shape = AppLeadingIconShape.rounded,
    this.size = AppLeadingIconSize.medium,
  });

  final IconData icon;
  final AppLeadingIconVariant variant;
  final AppLeadingIconType type;
  final AppLeadingIconShape shape;
  final AppLeadingIconSize size;

  static const double _tonalFillOpacity = 0.12;
  static const double _outlinedBorderWidth = 1.5;

  _LeadingIconSizeConfig _sizeConfig() => switch (size) {
    AppLeadingIconSize.small => (container: 32.0, icon: AppConstants.iconSmall),
    AppLeadingIconSize.medium => (
      container: AppConstants.touchTarget,
      icon: AppConstants.iconMedium,
    ),
    AppLeadingIconSize.large => (
      container: AppConstants.touchTarget + 16,
      icon: AppConstants.iconLarge,
    ),
  };

  /// The variant's color, plus the color that reads on top of it. Single
  /// source for every color the container paints.
  (Color, Color) _colorsOf(ThemeData theme) => switch (variant) {
    AppLeadingIconVariant.primary => (
      theme.colorScheme.primary,
      theme.colorScheme.onPrimary,
    ),
    AppLeadingIconVariant.secondary => (
      theme.colorScheme.secondary,
      theme.colorScheme.onSecondary,
    ),
    AppLeadingIconVariant.tertiary => (
      theme.colorScheme.tertiary,
      theme.colorScheme.onTertiary,
    ),
    AppLeadingIconVariant.danger => (
      theme.colorScheme.error,
      theme.colorScheme.onError,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final sizeConfig = _sizeConfig();
    final (accent, onAccent) = _colorsOf(theme);

    // No container: render the bare icon at the variant's color.
    if (type == AppLeadingIconType.plain) {
      return Icon(icon, size: sizeConfig.icon, color: accent);
    }

    // Variant chooses the color; type only decides how that color is applied.
    final (backgroundColor, iconColor) = switch (type) {
      AppLeadingIconType.filled => (accent, onAccent),
      AppLeadingIconType.tonal => (
        Color.alphaBlend(
          accent.withValues(alpha: _tonalFillOpacity),
          theme.colorScheme.surface,
        ),
        accent,
      ),
      AppLeadingIconType.outlined => (Colors.transparent, accent),
      AppLeadingIconType.plain => (Colors.transparent, accent),
    };

    final isCircle = shape == AppLeadingIconShape.circle;

    return Container(
      width: sizeConfig.container,
      height: sizeConfig.container,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : AppConstants.borderRadius12,
        border: type == AppLeadingIconType.outlined
            ? Border.all(color: accent, width: _outlinedBorderWidth)
            : null,
      ),
      child: Icon(icon, size: sizeConfig.icon, color: iconColor),
    );
  }
}
