import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import './app_input_format.dart';
import './app_input_style.dart';
import './input_title.dart';
import '../../../core/security/validation_service.dart';

/// A labeled text field — the kit's default way to collect a value.
///
/// [format] is the knob that matters: it picks the keyboard, the formatters
/// that keep junk out while typing, the autofill hints and the validation rule
/// in one go, so a money field only ever holds money.
///
///   AppInput(label: 'Email', format: AppInputFormat.email, required: true)
///   AppInput(label: 'Amount', format: AppInputFormat.money)
///   AppInput(label: 'Card', format: AppInputFormat.creditCard)
///
/// A formatted field still reads back as a plain value:
/// `AppInputFormat.money.unformat(controller.text)`.
///
/// Every decision the format makes can be overridden on the field —
/// [keyboardType], [inputFormatters], [autofillHints], [textCapitalization],
/// [obscureText], [maxLength], [validator].
///
/// How it *looks* — where the label goes, which variant, type, shape and size —
/// comes from [AppInputConfig.defaults] unless this field says otherwise, so
/// the app has one place to change its mind.
class AppInput extends StatefulWidget {
  const AppInput({
    super.key,
    required this.label,
    this.format = AppInputFormat.text,
    this.controller,
    this.initialValue,
    this.hint,
    this.required = false,
    this.enabled = true,
    this.readOnly = false,
    this.autoFocus = false,
    this.focusNode,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.showCounter,
    this.obscureText,
    this.showPasswordToggle = true,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization,
    this.inputFormatters,
    this.autofillHints,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.autovalidateMode,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.textAlign = TextAlign.start,
    this.labelMode,
    this.variant,
    this.type,
    this.shape,
    this.size,
  });

  final String label;

  /// What the field holds. Drives keyboard, formatters, autofill and
  /// validation together — see [AppInputFormat].
  final AppInputFormat format;

  final TextEditingController? controller;

  /// Seeds the field. With a [controller] it is only used while the controller
  /// is still empty, so an already-populated controller is never clobbered.
  final String? initialValue;

  final String? hint;

  /// Marks the label with an asterisk and rejects an empty value.
  final bool required;

  /// A disabled field is greyed out and cannot be focused.
  final bool enabled;

  /// A read-only field is styled normally but cannot be edited. Without an
  /// [onTap] it ignores pointers entirely; with one it stays tappable, which is
  /// how the picker-backed inputs are built.
  final bool readOnly;

  final bool autoFocus;
  final FocusNode? focusNode;

  /// Lines the field shows. An [AppInputFormat.multiline] field opens at five
  /// unless you say otherwise; `null` grows without limit.
  final int? maxLines;
  final int? minLines;

  /// Character cap. Defaults to the format's own where it has one (a card
  /// number, an expiry).
  final int? maxLength;

  /// Whether [maxLength] shows its counter. Null follows the config.
  final bool? showCounter;

  /// Hides the value. Defaults to the format's own answer — only
  /// [AppInputFormat.password] hides by default.
  final bool? obscureText;

  /// Shows the eye that reveals an obscured value, unless [suffixIcon] takes
  /// the slot. Turn it off for a value that should never be revealed.
  final bool showPasswordToggle;

  /// Overrides [AppInputFormat.keyboardType].
  final TextInputType? keyboardType;

  final TextInputAction? textInputAction;

  /// Overrides [AppInputFormat.textCapitalization].
  final TextCapitalization? textCapitalization;

  /// Replaces [AppInputFormat.formatters]. To keep them and add your own,
  /// spread them: `[...AppInputFormat.money.formatters, myFormatter]`.
  final List<TextInputFormatter>? inputFormatters;

  /// Overrides [AppInputFormat.autofillHints].
  final List<String>? autofillHints;

  final Widget? prefixIcon;
  final Widget? suffixIcon;

  /// Replaces the built-in rule entirely. Call [AppInput.validate] from inside
  /// it to add a rule on top instead of dropping validation.
  final String? Function(String? value)? validator;

  /// When the field validates itself. Null follows the config, which starts at
  /// Flutter's own default — on submit only.
  final AutovalidateMode? autovalidateMode;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;

  /// Alignment of the typed value and the hint. The label follows it too.
  final TextAlign textAlign;

  /// Where this field's label goes. Null follows the config — see
  /// [AppInputLabelMode].
  final AppInputLabelMode? labelMode;

  /// Null follows [AppInputConfig.defaults].
  final AppInputVariant? variant;
  final AppInputType? type;
  final AppInputShape? shape;
  final AppInputSize? size;

  /// The rule an [AppInput] applies when no [validator] is given: required
  /// first, then the format's own [ValidationService] check on the unformatted
  /// value. Empty optional fields pass.
  ///
  /// Exposed so a custom [validator] can layer on top of it:
  ///
  ///   validator: (v) =>
  ///       AppInput.validate(v, format: AppInputFormat.email, required: true) ??
  ///       (v!.endsWith('@work.com') ? null : 'Use your work address'),
  static String? validate(
    String? value, {
    AppInputFormat format = AppInputFormat.text,
    bool required = false,
  }) {
    final text = value ?? '';
    if (required && text.trim().isEmpty) {
      return AppInputStyle.config.requiredMessage;
    }
    if (text.isEmpty) return null;

    final result = ValidationService.validate(
      format.unformat(text),
      inputType: format.validationType,
    );
    return result.isValid ? null : result.error;
  }

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late bool _obscured;

  /// The format actually in force: an explicit [AppInput.format] wins, then the
  /// one a bare `keyboardType:` implies — so fields written before formats
  /// existed keep validating the way they did.
  AppInputFormat get _format => widget.format != AppInputFormat.text
      ? widget.format
      : AppInputFormat.forKeyboardType(widget.keyboardType) ??
            AppInputFormat.text;

  /// Whether this field hides its value at all — the eye shows for the whole
  /// life of such a field, not only while the value is hidden.
  bool get _obscurable => widget.obscureText ?? _format.isObscured;

  /// Where this field's label goes: its own answer, else the app's.
  AppInputLabelMode get _labelMode =>
      widget.labelMode ?? AppInputStyle.config.labelMode;

  @override
  void initState() {
    super.initState();
    _obscured = _obscurable;

    final controller = widget.controller;
    if (controller != null &&
        controller.text.isEmpty &&
        widget.initialValue != null) {
      controller.text = widget.initialValue!;
    }
  }

  @override
  void didUpdateWidget(AppInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.obscureText != oldWidget.obscureText ||
        widget.format != oldWidget.format) {
      _obscured = _obscurable;
    }
  }

  /// An obscured field is single-line by force; a multiline one opens at five
  /// lines unless the caller pinned a value.
  int? get _maxLines {
    if (_obscured) return 1;
    if (_format.isMultiline && widget.maxLines == 1) return 5;
    return widget.maxLines;
  }

  /// The caller's suffix, else the show/hide eye when there is one to show.
  Widget? get _suffixIcon {
    if (widget.suffixIcon != null) return widget.suffixIcon;
    if (!_obscurable || !widget.showPasswordToggle) return null;
    return IconButton(
      onPressed: () {
        HapticFeedback.selectionClick();
        setState(() => _obscured = !_obscured);
      },
      tooltip: _obscured ? 'Mostrar' : 'Ocultar',
      icon: Icon(
        _obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final format = _format;
    final accent = AppInputStyle.accentOf(context, widget.variant);

    final field = TextFormField(
      controller: widget.controller,
      initialValue: widget.controller == null ? widget.initialValue : null,
      focusNode: widget.focusNode,
      autofocus: widget.autoFocus,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      obscureText: _obscured,
      maxLines: _maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength ?? format.maxLength,
      keyboardType: widget.keyboardType ?? format.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization:
          widget.textCapitalization ?? format.textCapitalization,
      textAlign: widget.textAlign,
      inputFormatters: widget.inputFormatters ?? format.formatters,
      autofillHints: widget.autofillHints ?? format.autofillHints,
      autovalidateMode:
          widget.autovalidateMode ?? AppInputStyle.config.autovalidateMode,
      validator:
          widget.validator ??
          (value) => AppInput.validate(
            value,
            format: format,
            required: widget.required,
          ),
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      // Draws the message flush with the field rather than at the indent
      // Flutter puts it — see [AppInputStyle.decorationError].
      errorBuilder: (context, error) =>
          AppInputStyle.decorationError(context, error, type: widget.type),
      cursorColor: accent,
      style: AppInputStyle.valueStyle(
        context,
        size: widget.size,
        variant: widget.variant,
      ),
      decoration: AppInputStyle.decoration(
        context,
        variant: widget.variant,
        type: widget.type,
        shape: widget.shape,
        size: widget.size,
        label: widget.label,
        labelMode: _labelMode,
        required: widget.required,
        hint: widget.hint,
        enabled: widget.enabled,
        showCounter: widget.showCounter,
        // A label floating over several lines of text belongs at the first
        // line, not centred against the whole box.
        alignLabelWithHint: _maxLines != 1,
        prefixIcon: widget.prefixIcon,
        suffixIcon: _suffixIcon,
      ),
    );

    return InputFieldLayout(
      label: widget.label,
      required: widget.required,
      labelMode: _labelMode,
      variant: widget.variant,
      size: widget.size,
      textAlign: widget.textAlign,
      // A read-only field with nothing to tap shouldn't take focus or raise a
      // keyboard either.
      field: widget.readOnly && widget.onTap == null
          ? IgnorePointer(child: field)
          : field,
    );
  }
}
