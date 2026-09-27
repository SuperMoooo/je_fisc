import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// Color role of an input. Every color the input paints — border, focus ring,
/// cursor, icons, fill tint and the required marker — is derived from the
/// variant, so an [AppInputVariant.secondary] input is secondary all over.
///
/// Mirrors [AppButtonVariant] so the two widgets share one vocabulary.
enum AppInputVariant { primary, secondary, tertiary, danger }

/// Fill treatment of an input — how the [AppInputVariant] color is applied.
///
/// - [filled]: filled, borderless until focused.
/// - [outlined]: transparent with a visible border at rest.
/// - [underline]: bottom border only, no fill.
///
/// Orthogonal to [AppInputVariant] and [AppInputShape].
enum AppInputType { filled, outlined, underline }

/// Corner shape of an input. Ignored by [AppInputType.underline], which has no
/// corners to round.
enum AppInputShape { rounded, pill }

/// Text scale of an input — drives the value text, the hint, the icons and the
/// vertical padding together so the field grows as one.
enum AppInputSize { small, medium, large }

/// Where a field's label goes.
///
/// - [above]: its own line over the field, with the required marker.
/// - [floating]: inside the field, rising into the border on focus (Material).
/// - [placeholder]: no label; it is used as the hint until the user types.
/// - [none]: no label at all — the field is described by something else.
enum AppInputLabelMode { above, floating, placeholder, none }

/// Font, icon and padding metrics for one [AppInputSize].
typedef InputSizeConfig = ({
  double fontSize,
  double iconSize,
  double verticalPadding,
});

/// The one place the input family's look and behaviour is decided.
///
/// Every input in the kit reads [defaults] at build time for anything the call
/// site left unset. **Edit the [defaults] literal below** — that is the whole
/// point of this file, and nothing else in the app needs touching:
///
///   static AppInputConfig defaults = const AppInputConfig(
///     labelMode: AppInputLabelMode.floating,
///     type: AppInputType.outlined,
///     shape: AppInputShape.pill,
///   );
///
/// A single field still wins over the config when it says so:
///
///   AppInput(label: 'Email', labelMode: AppInputLabelMode.above)
///
/// **What belongs here and what does not.** Colors are not here on purpose:
/// they come from `ColorScheme` so they can differ between light and dark, and
/// the fill tint blends into `inputDecorationTheme.fillColor` from the theme.
/// The raw sizes are not here either — they are tokens in [AppConstants]. What
/// this file owns is how the inputs *use* those two: which token each size
/// picks, how strong the borders and tints are, and how a field is labelled.
class AppInputConfig {
  const AppInputConfig({
    this.labelMode = AppInputLabelMode.above,
    this.variant,
    this.type = AppInputType.filled,
    this.shape = AppInputShape.rounded,
    this.size = AppInputSize.medium,
    this.showRequiredMarker = true,
    this.requiredMarker = ' *',
    this.requiredMessage = 'This field is required',
    this.labelGap = AppConstants.space8,
    this.floatingLabelBehavior = FloatingLabelBehavior.auto,
    this.showCounter = false,
    this.autovalidateMode,
    this.searchableThreshold = 30,
    this.idleBorderWidth = 1,
    this.focusedBorderWidth = 1.5,
    this.idleBorderOpacity = 0.4,
    this.fillOpacity = 0.06,
    this.disabledOpacity = 0.38,
    this.hintOpacity = 0.35,
    this.smallMetrics = const (
      fontSize: AppConstants.fontSize14,
      iconSize: AppConstants.iconSmall,
      verticalPadding: AppConstants.space8,
    ),
    this.mediumMetrics = const (
      fontSize: AppConstants.fontSize16,
      iconSize: AppConstants.iconMedium,
      verticalPadding: (AppConstants.touchTarget - AppConstants.fontSize16) / 2,
    ),
    this.largeMetrics = const (
      fontSize: AppConstants.fontSize34,
      iconSize: AppConstants.iconLarge,
      verticalPadding: AppConstants.space16,
    ),
  });

  /// The config every input falls back to — edit this literal to restyle the
  /// app's inputs. Every argument is optional; what you leave out keeps the
  /// default shown in the constructor below.
  ///
  ///   static AppInputConfig defaults = const AppInputConfig(
  ///     labelMode: AppInputLabelMode.floating,
  ///   );
  ///
  /// It stays assignable for the cases a literal cannot cover — a flavor or a
  /// white-label build choosing at startup, or a test swapping it out. Do that
  /// before `runApp`: it is read during build, not watched, so a later change
  /// will not rebuild inputs already on screen.
  static AppInputConfig defaults = const AppInputConfig();

  // ── Labels ─────────────────────────────────────────────────────────────────

  /// Where labels go by default.
  final AppInputLabelMode labelMode;

  /// Whether a `required: true` field is marked at all.
  final bool showRequiredMarker;

  /// What marks a required field — `' *'`, `' (required)'`, anything.
  final String requiredMarker;

  /// What every input in the kit says when a required field is left empty.
  ///
  /// Each `validate` writes this message rather than its own copy, so the
  /// wording is one edit here — including translating it:
  ///
  ///   AppInputConfig.defaults = AppInputConfig(
  ///     requiredMessage: AppLocalizations.of(context).fieldRequired,
  ///   );
  ///
  /// It is read at validate time, so assigning [defaults] after a locale
  /// change re-words errors raised from then on.
  final String requiredMessage;

  /// Space between an [AppInputLabelMode.above] label and its field.
  final double labelGap;

  /// Whether an [AppInputLabelMode.floating] label starts inside the field and
  /// rises on focus ([FloatingLabelBehavior.auto]), sits above it always
  /// ([FloatingLabelBehavior.always]), or never floats.
  final FloatingLabelBehavior floatingLabelBehavior;

  // ── Defaults every input starts from ───────────────────────────────────────

  /// The color role every input takes when the call site names none.
  ///
  /// **Null — the default — means the theme paints them.** An input with no
  /// variant hands its colors back to `inputDecorationTheme`, `checkboxTheme`,
  /// `switchTheme` and the rest, so editing `config/theme/app_theme.dart` is
  /// what restyles the kit. Naming one here paints every input in that role
  /// instead, and the theme's own input colors stop being consulted.
  ///
  /// A single field still overrides either way:
  /// `AppInput(label: 'Amount', variant: AppInputVariant.danger)`.
  final AppInputVariant? variant;

  final AppInputType type;
  final AppInputShape shape;
  final AppInputSize size;

  /// Whether a field with a `maxLength` shows its counter.
  final bool showCounter;

  /// When fields validate themselves. Null keeps Flutter's default — validate
  /// on submit only. [AutovalidateMode.onUserInteraction] is the usual choice
  /// for a form that should correct itself as it is filled in.
  final AutovalidateMode? autovalidateMode;

  /// How many options an [AppDropdownInput] shows in a menu before it switches
  /// to a searchable sheet. A menu stops being usable somewhere around thirty
  /// rows; raise this for a list that stays scannable longer, or set it to 0 to
  /// make every dropdown searchable. A field can still answer for itself with
  /// `searchable: true` or `false`.
  final int searchableThreshold;

  // ── Border and fill ────────────────────────────────────────────────────────

  final double idleBorderWidth;
  final double focusedBorderWidth;

  /// How visible a resting border is, as a fraction of the variant color.
  final double idleBorderOpacity;

  /// How much of the variant color tints a filled input's background. If light
  /// and dark need different strengths, set `inputDecorationTheme.fillColor`
  /// per theme instead — this tint is blended into it.
  final double fillOpacity;

  final double disabledOpacity;
  final double hintOpacity;

  // ── Size metrics ───────────────────────────────────────────────────────────

  final InputSizeConfig smallMetrics;
  final InputSizeConfig mediumMetrics;
  final InputSizeConfig largeMetrics;

  /// The metrics behind one [AppInputSize].
  InputSizeConfig metricsOf(AppInputSize size) => switch (size) {
    AppInputSize.small => smallMetrics,
    AppInputSize.medium => mediumMetrics,
    AppInputSize.large => largeMetrics,
  };

  AppInputConfig copyWith({
    AppInputLabelMode? labelMode,
    AppInputVariant? variant,
    AppInputType? type,
    AppInputShape? shape,
    AppInputSize? size,
    bool? showRequiredMarker,
    String? requiredMarker,
    String? requiredMessage,
    double? labelGap,
    FloatingLabelBehavior? floatingLabelBehavior,
    bool? showCounter,
    AutovalidateMode? autovalidateMode,
    int? searchableThreshold,
    double? idleBorderWidth,
    double? focusedBorderWidth,
    double? idleBorderOpacity,
    double? fillOpacity,
    double? disabledOpacity,
    double? hintOpacity,
    InputSizeConfig? smallMetrics,
    InputSizeConfig? mediumMetrics,
    InputSizeConfig? largeMetrics,
  }) {
    return AppInputConfig(
      labelMode: labelMode ?? this.labelMode,
      variant: variant ?? this.variant,
      type: type ?? this.type,
      shape: shape ?? this.shape,
      size: size ?? this.size,
      showRequiredMarker: showRequiredMarker ?? this.showRequiredMarker,
      requiredMarker: requiredMarker ?? this.requiredMarker,
      requiredMessage: requiredMessage ?? this.requiredMessage,
      labelGap: labelGap ?? this.labelGap,
      floatingLabelBehavior:
          floatingLabelBehavior ?? this.floatingLabelBehavior,
      showCounter: showCounter ?? this.showCounter,
      autovalidateMode: autovalidateMode ?? this.autovalidateMode,
      searchableThreshold: searchableThreshold ?? this.searchableThreshold,
      idleBorderWidth: idleBorderWidth ?? this.idleBorderWidth,
      focusedBorderWidth: focusedBorderWidth ?? this.focusedBorderWidth,
      idleBorderOpacity: idleBorderOpacity ?? this.idleBorderOpacity,
      fillOpacity: fillOpacity ?? this.fillOpacity,
      disabledOpacity: disabledOpacity ?? this.disabledOpacity,
      hintOpacity: hintOpacity ?? this.hintOpacity,
      smallMetrics: smallMetrics ?? this.smallMetrics,
      mediumMetrics: mediumMetrics ?? this.mediumMetrics,
      largeMetrics: largeMetrics ?? this.largeMetrics,
    );
  }
}
