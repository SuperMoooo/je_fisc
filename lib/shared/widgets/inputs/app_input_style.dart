import 'package:flutter/material.dart';

import './app_input_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/extensions.dart';

// The vocabulary (variant, type, shape, size, label mode) lives with the config
// it configures, but every input reaches for it through this file — so one
// import still brings the whole set.
export './app_input_config.dart';

/// Resolves [AppInputVariant] + [AppInputType] into a concrete
/// [InputDecoration].
///
/// This overrides the global `inputDecorationTheme` on purpose: the theme can
/// only describe one variant, and inputs need all four. Colors come from the
/// [ColorScheme] so they follow light and dark; everything else — border
/// weights, tint strength, size metrics, where the label goes — comes from
/// [AppInputConfig.defaults].
class AppInputStyle {
  const AppInputStyle._();

  /// The app-wide input config. Every number below is read from it.
  static AppInputConfig get config => AppInputConfig.defaults;

  /// The variant in force: the field's, else [AppInputConfig.variant].
  ///
  /// Null means no variant is in play at all — the field never named one and
  /// the config does not either — and the widget should leave its colors to
  /// the theme.
  static AppInputVariant? variantOf(AppInputVariant? variant) =>
      variant ?? config.variant;

  /// The variant's color, or null when there is no variant to derive one from.
  ///
  /// **Null is the signal to hand a color slot back to the theme.** Passed
  /// straight into `Checkbox.activeColor`, `InputDecoration.prefixIconColor`
  /// or a `copyWith`, it leaves whatever `config/theme/app_theme.dart` set in
  /// place. Every widget in the kit paints through this, which is what makes
  /// editing the theme enough to restyle an app that names no variant.
  static Color? accentOrNull(BuildContext context, AppInputVariant? variant) {
    final resolved = variantOf(variant);
    if (resolved == null) return null;
    final colorScheme = context.theme.colorScheme;
    return switch (resolved) {
      AppInputVariant.primary => colorScheme.primary,
      AppInputVariant.secondary => colorScheme.secondary,
      AppInputVariant.tertiary => colorScheme.tertiary,
      AppInputVariant.danger => colorScheme.error,
    };
  }

  /// The variant's color, falling back to [ColorScheme.primary] where the
  /// slot has no themed default to fall through to — a cursor, a focus ring,
  /// a spinner. Prefer [accentOrNull] anywhere null can be passed on.
  static Color accentOf(BuildContext context, AppInputVariant? variant) =>
      accentOrNull(context, variant) ?? context.theme.colorScheme.primary;

  /// The color that reads on top of [accentOf] — what a checked box, a selected
  /// segment or a filled chip puts its glyph and label in.
  ///
  /// Every control that fills itself with the accent needs this, and each one
  /// guessing separately is how a selected segment ends up unreadable: the
  /// surface color is only the right answer in a light theme.
  static Color onAccentOf(BuildContext context, AppInputVariant? variant) =>
      onAccentOrNull(context, variant) ?? context.theme.colorScheme.onPrimary;

  /// [onAccentOf], null when no variant is in play — the companion to
  /// [accentOrNull], so a control fills and letters itself from the theme or
  /// from the variant as one decision rather than two.
  static Color? onAccentOrNull(BuildContext context, AppInputVariant? variant) {
    final resolved = variantOf(variant);
    if (resolved == null) return null;
    final colorScheme = context.theme.colorScheme;
    return switch (resolved) {
      AppInputVariant.primary => colorScheme.onPrimary,
      AppInputVariant.secondary => colorScheme.onSecondary,
      AppInputVariant.tertiary => colorScheme.onTertiary,
      AppInputVariant.danger => colorScheme.onError,
    };
  }

  /// The colour a field's trailing icon takes: the variant's, else whatever
  /// `inputDecorationTheme` gives every other field's suffix — so a control
  /// that draws its own chevron matches the ones that let the decoration do it.
  static Color? suffixIconColorOf(
    BuildContext context,
    AppInputVariant? variant,
  ) =>
      accentOrNull(context, variant) ??
      context.theme.inputDecorationTheme.suffixIconColor;

  /// Font, icon and padding metrics for a size. Retune the scale in
  /// [AppInputConfig], not here.
  static InputSizeConfig configOf(AppInputSize? size) =>
      config.metricsOf(size ?? config.size);

  /// Style for the text the user types. Pair with [decoration] of the same size.
  static TextStyle? textStyle(BuildContext context, {AppInputSize? size}) =>
      context.theme.textTheme.bodyMedium?.copyWith(
        fontSize: configOf(size).fontSize,
      );

  /// Style for the value a field is holding — what was typed into it, or the
  /// label of whatever was picked in it.
  ///
  /// A field with a variant puts its value in that variant's color and weights
  /// it, so the content reads louder than the chrome around it. **Without one,
  /// the theme's own body style is handed back untouched** — `copyWith`
  /// ignores a null, so nothing is overpainted with a guess and
  /// `app_theme.dart`'s `textTheme` is what styles the value.
  static TextStyle? valueStyle(
    BuildContext context, {
    AppInputSize? size,
    AppInputVariant? variant,
    bool enabled = true,
  }) {
    final accent = accentOrNull(context, variant);
    return textStyle(context, size: size)?.copyWith(
      color: enabled
          ? accent
          : context.colorScheme.onSurface.withValues(
              alpha: config.disabledOpacity,
            ),
      fontWeight: accent == null ? null : FontWeight.bold,
    );
  }

  /// [TextAlign] as an [AlignmentGeometry], for widgets that align a child box
  /// rather than a run of text — the dropdown's items and hint.
  static AlignmentGeometry alignmentOf(TextAlign textAlign) =>
      switch (textAlign) {
        TextAlign.center => Alignment.center,
        TextAlign.right || TextAlign.end => AlignmentDirectional.centerEnd,
        _ => AlignmentDirectional.centerStart,
      };

  /// The label with its required marker appended, when the config shows one.
  /// Used by the label modes that render inside the field; an above-label is
  /// drawn by `InputTitle`, which styles the marker instead of inlining it.
  static String? markedLabel(String? label, {bool required = false}) {
    if (label == null) return null;
    return required && config.showRequiredMarker
        ? '$label${config.requiredMarker}'
        : label;
  }

  /// How a validation message is drawn. One style, so the line under a text
  /// field and the one a checkbox draws for itself match.
  static TextStyle? errorStyle(BuildContext context) =>
      context.textTheme.bodySmall?.copyWith(color: context.colorScheme.error);

  /// The message an [InputDecoration] shows when a field fails validation,
  /// pulled back into line with the field's own left edge.
  ///
  /// Flutter lays that line out at the decoration's `contentPadding`, so by
  /// default it sits indented under a field whose [AppInputLabelMode.above]
  /// label is flush with the edge — the label starts at one x and the error
  /// explaining it at another. That slot has no padding of its own to set, so
  /// the message is shifted back by the indent instead.
  ///
  /// Hand it to `TextFormField.errorBuilder`, or to [InputDecoration.error] on
  /// a field built from a bare [FormField]. Never to `errorText` — an
  /// [InputDecoration] refuses to hold both.
  static Widget decorationError(
    BuildContext context,
    String errorText, {
    AppInputType? type,
  }) {
    final indent = _subtextIndentOf(type ?? config.type);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Transform.translate(
      offset: Offset(rtl ? indent : -indent, 0),
      child: Text(errorText, style: errorStyle(context)),
    );
  }

  /// [decorationError] for a message that may be absent — what a hand-built
  /// [FormField] hands straight to [InputDecoration.error].
  static Widget? decorationErrorOrNull(
    BuildContext context,
    String? errorText, {
    AppInputType? type,
  }) => errorText == null
      ? null
      : decorationError(context, errorText, type: type);

  /// Where a decoration starts the line under a field: the horizontal
  /// `contentPadding` [decoration] sets, plus the gap an outlined border
  /// reserves for its floating label. An underline field pads neither, so its
  /// message is already flush.
  static double _subtextIndentOf(AppInputType type) =>
      type == AppInputType.underline
      ? 0
      : AppConstants.space12 + _outlineGapPadding;

  /// `OutlineInputBorder.gapPadding`'s default, which [_border] leaves alone.
  static const double _outlineGapPadding = 4;

  static bool _isFilled(AppInputType type) => type == AppInputType.filled;

  static BorderRadius _radiusOf(AppInputType type, AppInputShape shape) =>
      switch (type) {
        AppInputType.underline => BorderRadius.zero,
        _ => switch (shape) {
          AppInputShape.rounded => AppConstants.borderRadius12,
          AppInputShape.pill => AppConstants.borderRadiusFull,
        },
      };

  /// The color the theme drew a border in — what a field with no variant to
  /// derive one from should use. [fallback] covers a theme that left the slot
  /// alone, and a [BorderSide.none], which is a width of zero rather than a
  /// color worth reusing.
  static Color _themedBorderColor(InputBorder? border, Color fallback) {
    final side = border?.borderSide;
    if (side == null || side.style == BorderStyle.none) return fallback;
    return side.color;
  }

  static InputBorder _border(
    AppInputType type,
    AppInputShape shape,
    Color color,
    double width,
  ) {
    final side = BorderSide(color: color, width: width);
    if (type == AppInputType.underline) {
      return UnderlineInputBorder(borderSide: side);
    }
    return OutlineInputBorder(
      borderRadius: _radiusOf(type, shape),
      borderSide: side,
    );
  }

  /// Builds the decoration for an input.
  ///
  /// Anything left null falls back to [AppInputConfig.defaults], so a field
  /// that says nothing looks like the rest of the app. [label] is only painted
  /// here for the label modes that live inside the field —
  /// [AppInputLabelMode.floating] and [AppInputLabelMode.placeholder].
  static InputDecoration decoration(
    BuildContext context, {
    AppInputVariant? variant,
    AppInputType? type,
    AppInputShape? shape,
    AppInputSize? size,
    String? label,
    AppInputLabelMode? labelMode,
    bool required = false,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool enabled = true,
    bool? showCounter,
    bool alignLabelWithHint = false,
  }) {
    final theme = context.theme;
    final resolvedType = type ?? config.type;
    final resolvedShape = shape ?? config.shape;
    final resolvedSize = size ?? config.size;
    final mode = labelMode ?? config.labelMode;

    final accent = accentOrNull(context, variant);
    final decorationTheme = theme.inputDecorationTheme;
    final errorColor = theme.colorScheme.error;
    final filled = _isFilled(resolvedType);
    final sizeConfig = configOf(resolvedSize);

    // Size the icons through an IconTheme so callers can still override with an
    // explicit `Icon(..., size: x)`.
    Widget? sized(Widget? icon) => icon == null
        ? null
        : IconTheme.merge(
            data: IconThemeData(size: sizeConfig.iconSize),
            child: icon,
          );

    // Filled inputs carry their color in the fill, so they stay borderless
    // until focused. Outlined and underline inputs need a visible resting edge
    // — which, with no variant to draw it from, is the one the theme drew.
    final idleColor = filled
        ? Colors.transparent
        : accent?.withValues(alpha: config.idleBorderOpacity) ??
              _themedBorderColor(
                decorationTheme.enabledBorder ?? decorationTheme.border,
                theme.colorScheme.outline,
              );
    final focusedColor =
        accent ??
        _themedBorderColor(
          decorationTheme.focusedBorder,
          theme.colorScheme.primary,
        );
    final disabledColor = theme.colorScheme.onSurface.withValues(
      alpha: config.disabledOpacity / 2,
    );

    // The theme's own fill — the same color AppCard paints — so a field and a
    // card standing next to each other read as one surface.
    final baseFill = decorationTheme.fillColor ?? theme.colorScheme.surface;

    final marked = markedLabel(label, required: required);

    return InputDecoration(
      // Only the in-field modes draw the label here: `above` is a separate
      // widget over the field, and `none` drops it entirely.
      labelText: mode == AppInputLabelMode.floating ? marked : null,
      floatingLabelBehavior: config.floatingLabelBehavior,
      alignLabelWithHint: alignLabelWithHint,
      hintText: mode == AppInputLabelMode.placeholder ? (hint ?? marked) : hint,
      prefixIcon: sized(prefixIcon),
      suffixIcon: sized(suffixIcon),
      enabled: enabled,
      filled: filled,
      // A variant tints that fill rather than replacing it, so the field still
      // sits correctly on the surface in light and dark alike. With no variant
      // there is nothing to tint with, and the theme's fill is already right.
      fillColor: !filled
          ? Colors.transparent
          : accent == null
          ? baseFill
          : Color.alphaBlend(
              accent.withValues(alpha: config.fillOpacity),
              baseFill,
            ),
      border: _border(
        resolvedType,
        resolvedShape,
        idleColor,
        config.idleBorderWidth,
      ),
      enabledBorder: _border(
        resolvedType,
        resolvedShape,
        idleColor,
        config.idleBorderWidth,
      ),
      focusedBorder: _border(
        resolvedType,
        resolvedShape,
        focusedColor,
        config.focusedBorderWidth,
      ),
      disabledBorder: _border(
        resolvedType,
        resolvedShape,
        disabledColor,
        config.idleBorderWidth,
      ),
      errorBorder: _border(
        resolvedType,
        resolvedShape,
        errorColor,
        config.idleBorderWidth,
      ),
      focusedErrorBorder: _border(
        resolvedType,
        resolvedShape,
        errorColor,
        config.focusedBorderWidth,
      ),
      prefixIconColor: enabled ? accent : disabledColor,
      suffixIconColor: enabled ? accent : disabledColor,
      // At rest a floating label sits where the hint would, so it reads like
      // one; once it floats it becomes the field's accent. With no variant in
      // play the color is left null, and the theme's own label and hint styles
      // come through underneath — only the size is imposed on top.
      labelStyle: (decorationTheme.labelStyle ?? theme.textTheme.bodyMedium)
          ?.copyWith(
            color: enabled
                ? accent?.withValues(alpha: config.hintOpacity)
                : disabledColor,
            fontSize: sizeConfig.fontSize,
          ),
      floatingLabelStyle:
          (decorationTheme.floatingLabelStyle ?? theme.textTheme.bodyMedium)
              ?.copyWith(color: enabled ? accent : disabledColor),
      hintStyle: (decorationTheme.hintStyle ?? theme.textTheme.bodyMedium)
          ?.copyWith(
            color: accent?.withValues(alpha: config.hintOpacity),
            fontSize: sizeConfig.fontSize,
          ),
      // The counter is opt-in: a maxLength is usually a guard rail, not
      // something the user needs to watch tick down.
      counterText: (showCounter ?? config.showCounter) ? null : '',
      contentPadding: EdgeInsets.symmetric(
        vertical: sizeConfig.verticalPadding,
        horizontal: resolvedType == AppInputType.underline
            ? 0
            : AppConstants.space12,
      ),
    );
  }
}

/// Renders [child] exactly as it looks when live, but inert.
///
/// This is what separates read-only from disabled across the kit. A disabled
/// control greys itself out because its value is not the user's to set — the
/// form is waiting on something else first. A read-only one keeps every color
/// it would have had, because the value it is showing is real and worth
/// reading; it simply cannot be changed from here. Greying it out would say
/// the wrong thing about the data.
///
/// Which is why the controls behind this gate hand Material a callback even
/// when the caller gave them none. A `Checkbox`, a `Switch` or a `Slider` greys
/// itself out the moment its callback goes null, and not greying out is the
/// whole point of read-only — so they pass one that is never reached, this gate
/// having already taken the pointer and the focus away. `readOnly: true` is the
/// entire thing a caller has to write; nobody should have to invent an
/// `onChanged: (_) {}` to keep a frozen control from looking disabled.
///
/// [AppInput] and the fields built on it hand `readOnly` to Flutter's own.
/// Every other control in the kit — from [AppCheckbox] to a whole calendar —
/// wraps itself in this instead and goes on painting as if enabled.
class ReadOnlyGate extends StatelessWidget {
  const ReadOnlyGate({super.key, required this.readOnly, required this.child});

  final bool readOnly;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!readOnly) return child;
    // Focus is excluded as well as pointers: a control the finger cannot reach
    // must not be reachable by keyboard either, or a tab lands on something
    // that then refuses to answer.
    return Semantics(
      readOnly: true,
      child: ExcludeFocus(child: IgnorePointer(child: child)),
    );
  }
}
