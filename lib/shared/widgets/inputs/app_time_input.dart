import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import './app_input_style.dart';
import './cupertino_picker_sheet.dart';
import './input_title.dart';
import '../../../core/utils/extensions.dart';

/// A read-only field that opens whichever time picker its platform is used to:
/// the Material clock dialog on Android, the iOS wheel in a bottom sheet
/// anywhere else. Both paths hand back one [TimeOfDay], so the call site never
/// has to know which one ran.
class AppTimeInput extends StatefulWidget {
  const AppTimeInput({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.initialValue,
    this.enabled = true,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.focusNode,
    this.autoFocus = false,
    this.required = false,
    this.validator,
    this.autovalidateMode,
    this.labelMode,
    this.variant,
    this.type,
    this.shape,
    this.size,
    this.textAlign = TextAlign.start,
    this.onChanged,
  });

  /// Optional external controller — pass one to read or clear the time from
  /// outside. When omitted the field owns (and disposes) its own, so a value
  /// still shows without one.
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final TimeOfDay? initialValue;

  /// A disabled field is greyed out and opens nothing.
  final bool enabled;

  /// Styled normally but opens no picker — for a time that is displayed rather
  /// than chosen.
  final bool readOnly;

  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final bool autoFocus;

  /// Marks the label, and — unless [validator] replaces the rule — rejects an
  /// empty field when the form validates.
  final bool required;

  /// Replaces the built-in rule entirely. Receives the field's text.
  /// Call [AppTimeInput.validate] from inside it to add a rule on top instead
  /// of dropping the required check.
  final String? Function(String? value)? validator;

  /// When the field validates itself. Null follows the config.
  final AutovalidateMode? autovalidateMode;

  /// Null follows [AppInputConfig.defaults].
  final AppInputLabelMode? labelMode;
  final AppInputVariant? variant;
  final AppInputType? type;
  final AppInputShape? shape;
  final AppInputSize? size;

  /// Alignment of the displayed time and the hint. The label follows it too.
  final TextAlign textAlign;

  /// Fires with the picked time.
  final ValueChanged<TimeOfDay>? onChanged;

  /// The rule applied when no [validator] is given: a required field has to
  /// hold a time.
  static String? validate(String? value, {bool required = false}) =>
      required && (value == null || value.trim().isEmpty)
      ? AppInputStyle.config.requiredMessage
      : null;

  @override
  State<AppTimeInput> createState() => _AppTimeInputState();
}

class _AppTimeInputState extends State<AppTimeInput> {
  /// The field shows whatever this holds, so it has to exist even when the
  /// caller passes nothing — otherwise a picked time would update the state
  /// and never appear on screen.
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();

  /// Only dispose what this widget created; an injected controller belongs to
  /// the caller and may well outlive the field.
  late final bool _ownsController = widget.controller == null;

  TimeOfDay _lastSelectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _lastSelectedTime = widget.initialValue!;
      // A controller that already holds something was seeded by the caller,
      // and that beats a default.
      if (_controller.text.isEmpty) {
        _controller.text = widget.initialValue!.formattedTime;
      }
    }
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    HapticFeedback.selectionClick();
    // The picker is chosen and opened before anything is awaited, so the
    // context is never carried across the gap.
    final picker = Platform.isAndroid
        ? _showMaterialPicker(context)
        : _showCupertinoPicker(context);

    final picked = await picker;
    if (picked == null || !mounted) return;

    HapticFeedback.selectionClick();
    setState(() {
      _lastSelectedTime = picked;
      _controller.text = picked.formattedTime;
    });
    widget.onChanged?.call(picked);
  }

  Future<TimeOfDay?> _showMaterialPicker(BuildContext context) {
    return showTimePicker(
      context: context,
      initialTime: _lastSelectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
            alwaysUse24HourFormat: true,
          ),
          child: child!,
        );
      },
    );
  }

  Future<TimeOfDay?> _showCupertinoPicker(BuildContext context) {
    final accent = AppInputStyle.accentOf(context, widget.variant);

    // The wheel reports every time it rolls past; only the one showing when
    // Done is tapped counts, so it is parked here until then.
    var pending = _lastSelectedTime;

    return showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => CupertinoPickerSheet(
        accent: accent,
        onCancel: () => Navigator.pop(sheetContext),
        onDone: () => Navigator.pop(sheetContext, pending),
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.time,
          // The wheel only works in DateTime; which day it sits on is
          // irrelevant, since only the time is read back out.
          initialDateTime: _lastSelectedTime.onDate(DateTime.now()),
          use24hFormat: true,
          onDateTimeChanged: (value) => pending = TimeOfDay.fromDateTime(value),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppInputStyle.accentOf(context, widget.variant);

    return InputFieldLayout(
      label: widget.label,
      required: widget.required,
      labelMode: widget.labelMode,
      variant: widget.variant,
      size: widget.size,
      textAlign: widget.textAlign,
      field: TextFormField(
        // A read-only field keeps its normal look but opens nothing; a disabled
        // one is greyed out by `enabled` and never reaches this callback.
        onTap: widget.readOnly ? null : () => _selectTime(context),
        focusNode: widget.focusNode,
        autofocus: widget.autoFocus,
        enabled: widget.enabled,
        // Always true: the value is chosen in a picker, never typed.
        readOnly: true,
        controller: _controller,
        autovalidateMode:
            widget.autovalidateMode ?? AppInputStyle.config.autovalidateMode,
        validator:
            widget.validator ??
            (value) => AppTimeInput.validate(value, required: widget.required),
        errorBuilder: (context, error) =>
            AppInputStyle.decorationError(context, error, type: widget.type),
        style: AppInputStyle.valueStyle(
          context,
          size: widget.size,
          variant: widget.variant,
        ),
        textAlign: widget.textAlign,
        cursorColor: accent,
        decoration: AppInputStyle.decoration(
          context,
          variant: widget.variant,
          type: widget.type,
          shape: widget.shape,
          size: widget.size,
          label: widget.label,
          labelMode: widget.labelMode,
          required: widget.required,
          hint: widget.hint,
          enabled: widget.enabled,
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.suffixIcon,
        ),
      ),
    );
  }
}
