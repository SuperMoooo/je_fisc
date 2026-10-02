import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/extensions.dart';

/// Visual weight of an [AppHeading] — how much of the screen the title claims.
///
/// - [display]: the screen's own title, hero-sized.
/// - [large]: a major section that opens a new context.
/// - [medium]: the everyday heading above a list or a form block.
/// - [small]: a sub-heading inside a section.
/// - [label]: the small uppercased eyebrow over a settings group.
enum AppHeadingSize { display, large, medium, small, label }

/// Color role of an [AppHeading] — the kit's four roles, plus [neutral] for
/// the default `onSurface` (a heading is structure, not accent) and [muted]
/// for the group label that should stay in the background.
enum AppHeadingVariant { primary, secondary, tertiary, danger, neutral, muted }

/// Where the heading sits in the width it is given. Moves the title, the
/// subtitle and the icon together.
enum AppHeadingAlign { start, center, end }

typedef _HeadingSizeConfig = ({
  double fontSize,
  double subtitleSize,
  FontWeight weight,
  double letterSpacing,
  bool uppercase,
});

/// The title before a thing — a page, a list, a settings group, a form block.
///
/// Typography only, announced as a header to screen readers. For the header
/// *row* with a "See all" action there is [AppSectionHeader]; for the
/// screen's chrome, [AppAppBar].
///
/// ```dart
/// AppHeading(title: 'Settings', size: AppHeadingSize.large),
/// // ...
/// AppHeading(
///   title: 'Notifications',
///   size: AppHeadingSize.label,
///   variant: AppHeadingVariant.muted,
/// ),
/// AppListTile(...),
/// ```
class AppHeading extends StatelessWidget {
  const AppHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.size = AppHeadingSize.medium,
    this.variant = AppHeadingVariant.neutral,
    this.align = AppHeadingAlign.start,
    this.icon,
    this.trailing,
    this.color,
    this.subtitleColor,
    this.weight,
    this.uppercase,
    this.maxLines,
    this.divider = false,
    this.padding = const EdgeInsets.symmetric(vertical: AppConstants.space8),
  });

  final String title;

  /// Supporting line under the title. Quiet whatever the [variant] says —
  /// only [subtitleColor] changes it.
  final String? subtitle;

  final AppHeadingSize size;
  final AppHeadingVariant variant;

  /// The heading takes the full width it is offered, so [AppHeadingAlign.center]
  /// and [AppHeadingAlign.end] always have room to act.
  final AppHeadingAlign align;

  /// Leading icon, sized to the title and painted its color.
  final IconData? icon;

  /// Anything that belongs on the heading's right edge — an [AppIconButton],
  /// a tag, a count. The title column keeps the rest of the width.
  final Widget? trailing;

  /// Overrides [variant]'s color — the escape hatch for a tint the variant
  /// vocabulary doesn't name.
  final Color? color;

  /// Overrides the subtitle's `onSurfaceVariant`.
  final Color? subtitleColor;

  /// Overrides [size]'s weight.
  final FontWeight? weight;

  /// Null follows [size]: only [AppHeadingSize.label] capitalizes. Set it to
  /// force either look at any size — caps bring letter spacing with them.
  final bool? uppercase;

  /// Lines the title may take before it ellipsizes. Unlimited by default.
  final int? maxLines;

  /// Draws a hairline rule under the heading — the settings-page way of
  /// marking where a group starts.
  final bool divider;

  final EdgeInsetsGeometry padding;

  /// Uppercase without tracking reads cramped, so caps at any size get at
  /// least the label size's spacing.
  static const double _capsLetterSpacing = 0.8;

  /// An icon next to text is drawn a shade larger than the glyphs — they sit
  /// inside their em box while the icon fills its own.
  static const double _iconScale = 1.15;

  _HeadingSizeConfig _sizeConfig() => switch (size) {
    AppHeadingSize.display => (
      fontSize: AppConstants.fontSize34,
      subtitleSize: AppConstants.fontSize16,
      weight: FontWeight.w700,
      letterSpacing: -0.5,
      uppercase: false,
    ),
    AppHeadingSize.large => (
      fontSize: AppConstants.fontSize28,
      subtitleSize: AppConstants.fontSize15,
      weight: FontWeight.w700,
      letterSpacing: -0.25,
      uppercase: false,
    ),
    AppHeadingSize.medium => (
      fontSize: AppConstants.fontSize22,
      subtitleSize: AppConstants.fontSize14,
      weight: FontWeight.w600,
      letterSpacing: 0,
      uppercase: false,
    ),
    AppHeadingSize.small => (
      fontSize: AppConstants.fontSize17,
      subtitleSize: AppConstants.fontSize13,
      weight: FontWeight.w600,
      letterSpacing: 0,
      uppercase: false,
    ),
    AppHeadingSize.label => (
      fontSize: AppConstants.fontSize13,
      subtitleSize: AppConstants.fontSize12,
      weight: FontWeight.w600,
      letterSpacing: _capsLetterSpacing,
      uppercase: true,
    ),
  };

  /// The theme role each size starts from, so the app's font family and any
  /// theme-level tweaks flow through before the size metrics land on top.
  TextStyle? _baseStyle(TextTheme textTheme) => switch (size) {
    AppHeadingSize.display => textTheme.headlineLarge,
    AppHeadingSize.large => textTheme.headlineMedium,
    AppHeadingSize.medium => textTheme.titleLarge,
    AppHeadingSize.small => textTheme.titleMedium,
    AppHeadingSize.label => textTheme.labelSmall,
  };

  Color _variantColor(ThemeData theme) => switch (variant) {
    AppHeadingVariant.primary => theme.colorScheme.primary,
    AppHeadingVariant.secondary => theme.colorScheme.secondary,
    AppHeadingVariant.tertiary => theme.colorScheme.tertiary,
    AppHeadingVariant.danger => theme.colorScheme.error,
    AppHeadingVariant.neutral => theme.colorScheme.onSurface,
    AppHeadingVariant.muted => theme.colorScheme.onSurfaceVariant,
  };

  TextAlign get _textAlign => switch (align) {
    AppHeadingAlign.start => TextAlign.start,
    AppHeadingAlign.center => TextAlign.center,
    AppHeadingAlign.end => TextAlign.end,
  };

  CrossAxisAlignment get _crossAlign => switch (align) {
    AppHeadingAlign.start => CrossAxisAlignment.start,
    AppHeadingAlign.center => CrossAxisAlignment.center,
    AppHeadingAlign.end => CrossAxisAlignment.end,
  };

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final config = _sizeConfig();
    final accent = color ?? _variantColor(theme);
    final caps = uppercase ?? config.uppercase;

    final titleStyle = (_baseStyle(theme.textTheme) ?? const TextStyle())
        .copyWith(
          color: accent,
          fontSize: config.fontSize,
          fontWeight: weight ?? config.weight,
          letterSpacing: caps && config.letterSpacing < _capsLetterSpacing
              ? _capsLetterSpacing
              : config.letterSpacing,
        );

    Widget titleLine = Text(
      caps ? title.toUpperCase() : title,
      textAlign: _textAlign,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: titleStyle,
    );
    if (icon != null) {
      titleLine = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: config.fontSize * _iconScale, color: accent),
          const SizedBox(width: AppConstants.space8),
          Flexible(child: titleLine),
        ],
      );
    }

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: _crossAlign,
      children: [
        titleLine,
        if (subtitle != null) ...[
          const SizedBox(height: AppConstants.space4),
          Text(
            subtitle!,
            textAlign: _textAlign,
            style: (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
              color: subtitleColor ?? theme.colorScheme.onSurfaceVariant,
              fontSize: config.subtitleSize,
            ),
          ),
        ],
      ],
    );

    if (trailing != null) {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: content),
          const SizedBox(width: AppConstants.space8),
          trailing!,
        ],
      );
    }

    if (divider) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          content,
          const SizedBox(height: AppConstants.space8),
          Divider(
            height: 1,
            thickness: 1,
            color: theme.colorScheme.outlineVariant,
          ),
        ],
      );
    }

    // Full width so [align] has the room it aligns within — a heading paints
    // no background, so the claim costs nothing.
    return Semantics(
      header: true,
      child: Padding(
        padding: padding,
        child: SizedBox(width: double.infinity, child: content),
      ),
    );
  }
}
