import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/extensions.dart';

/// The iOS convention for a wheel picker: a Cancel / Done bar above the wheel,
/// on a sheet the caller pops with whatever the wheel was showing.
///
/// Used by [AppDateInput] and [AppTimeInput] on every platform but Android, and
/// reusable for any other wheel — drop a [CupertinoPicker] in as the [child]:
///
/// ```dart
/// showModalBottomSheet<String>(
///   context: context,
///   backgroundColor: Colors.transparent,
///   builder: (sheetContext) => CupertinoPickerSheet(
///     accent: Theme.of(context).colorScheme.primary,
///     onCancel: () => Navigator.pop(sheetContext),
///     onDone: () => Navigator.pop(sheetContext, pending),
///     child: CupertinoPicker(...),
///   ),
/// );
/// ```
///
/// It stays on Material surface colors rather than Cupertino's own, so the
/// sheet matches the rest of the app instead of the rest of iOS.
class CupertinoPickerSheet extends StatelessWidget {
  const CupertinoPickerSheet({
    super.key,
    required this.child,
    required this.accent,
    required this.onCancel,
    required this.onDone,
    this.wheelHeight = _defaultWheelHeight,
  });

  /// The wheel itself — a [CupertinoDatePicker] or a [CupertinoPicker].
  final Widget child;

  /// Colors the confirm action. Pass the variant color of the field that
  /// opened the sheet so the two read as one control.
  final Color accent;

  /// Dismiss without a value. Pop the sheet with nothing.
  final VoidCallback onCancel;

  /// Confirm. Pop the sheet with the value the wheel last reported.
  final VoidCallback onDone;

  /// A wheel is not laid out from its content, so it needs a height. 216 is
  /// what iOS gives one; raise it for a wheel with more columns.
  final double wheelHeight;

  static const double _defaultWheelHeight = 216;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final localizations = MaterialLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.radius24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onCancel();
                  },
                  child: Text(
                    localizations.cancelButtonLabel,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                CupertinoButton(
                  // The haptic for a confirmed pick belongs to whoever acts on
                  // the value, so this one only reports it.
                  onPressed: onDone,
                  child: Text(
                    localizations.okButtonLabel,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            SizedBox(
              height: wheelHeight,
              child: MediaQuery(
                // The wheel has a fixed height, so a large text scale would
                // clip its rows instead of growing the sheet.
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.noScaling,
                  alwaysUse24HourFormat: true,
                ),
                child: CupertinoTheme(
                  // The wheel paints its labels from the Cupertino theme, not
                  // the Material one — without this they stay dark in dark mode.
                  data: CupertinoThemeData(
                    brightness: theme.brightness,
                    primaryColor: accent,
                  ),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
