import 'package:flutter/material.dart';
import './app_input_style.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/extensions.dart';

/// The label an [AppInputLabelMode.above] field wears, with its required
/// marker styled in the field's own accent.
///
/// The other label modes never build this — they hand the label to the
/// decoration instead, so it can sit inside the field.
class InputTitle extends StatelessWidget {
  const InputTitle({
    super.key,
    required this.label,
    required this.required,
    this.variant,
    this.size,
    this.textAlign = TextAlign.start,
  });

  final String label;
  final bool required;

  /// Null follows [AppInputConfig.defaults].
  final AppInputVariant? variant;
  final AppInputSize? size;

  /// Kept in step with the field's own alignment so the label sits over the
  /// text it describes.
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final config = AppInputStyle.config;
    final fontSize = AppInputStyle.configOf(size).fontSize;

    return Text.rich(
      textAlign: textAlign,
      TextSpan(
        text: label,
        style: textTheme.bodyLarge?.copyWith(fontSize: fontSize),
        children: required && config.showRequiredMarker
            ? [
                TextSpan(
                  text: config.requiredMarker,
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppInputStyle.accentOf(context, variant),
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                  ),
                ),
              ]
            : [],
      ),
    );
  }
}

/// Puts a field under its [InputTitle] when labels go [AppInputLabelMode.above],
/// and returns the field untouched for every other mode — where the label is
/// already part of the decoration, or gone.
///
/// Every labeled input in the kit lays itself out through this, so the label
/// mode is decided in exactly one place.
class InputFieldLayout extends StatelessWidget {
  const InputFieldLayout({
    super.key,
    required this.label,
    required this.required,
    required this.field,
    this.labelMode,
    this.variant,
    this.size,
    this.textAlign = TextAlign.start,
  });

  final String label;
  final bool required;
  final Widget field;

  /// Null follows [AppInputConfig.defaults].
  final AppInputLabelMode? labelMode;
  final AppInputVariant? variant;
  final AppInputSize? size;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final config = AppInputStyle.config;
    if ((labelMode ?? config.labelMode) != AppInputLabelMode.above) {
      return field;
    }

    return Column(
      spacing: config.labelGap,
      // Stretch so the label can align itself against the field's full width.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InputTitle(
          label: label,
          required: required,
          variant: variant,
          size: size,
          textAlign: textAlign,
        ),
        field,
      ],
    );
  }
}

/// Makes a control that carries its own selection — a checkbox, a radio group,
/// a chip row — validate like the rest of the family.
///
/// The fields built on [InputDecoration] get `errorText` for free: a border to
/// turn red and a line underneath to explain it. A checkbox paints neither, so
/// a `Form` that rejects one has nowhere to say why. This wraps the control in
/// a [FormField] and puts that line under it.
///
/// ```dart
/// SelectionFormField<bool>(
///   value: _accepted,
///   validator: (v) => v ? null : 'Please accept the terms',
///   builder: (_) => AppCheckboxLabel(...),
/// )
/// ```
class SelectionFormField<T> extends StatelessWidget {
  const SelectionFormField({
    super.key,
    required this.value,
    required this.validator,
    required this.builder,
    this.enabled = true,
    this.autovalidateMode,
  });

  /// The control's current selection, read from the caller on every validate
  /// rather than stored — the caller owns it, so its answer is the true one
  /// even before a rebuild has reached this field.
  final T value;

  /// Null leaves the control out of validation altogether, and no error line is
  /// ever built.
  final String? Function(T value)? validator;

  final Widget Function(FormFieldState<T> state) builder;
  final bool enabled;

  /// Null follows [AppInputConfig.defaults].
  final AutovalidateMode? autovalidateMode;

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      initialValue: value,
      enabled: enabled,
      autovalidateMode:
          autovalidateMode ?? AppInputStyle.config.autovalidateMode,
      // A null [validator] resolves to no rule, so an unvalidated control still
      // builds exactly as it did — it simply never has anything to report.
      validator: (_) => validator?.call(value),
      builder: (state) {
        final error = state.errorText;
        return Column(
          mainAxisSize: MainAxisSize.min,
          // Stretch so the control keeps the width it had before it was
          // wrapped: a row-wide tap target must not shrink to its content.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            builder(state),
            // Flush with the control it explains, the way the fields built on
            // [InputDecoration] draw theirs.
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppConstants.space4),
                child: Text(error, style: AppInputStyle.errorStyle(context)),
              ),
          ],
        );
      },
    );
  }
}
