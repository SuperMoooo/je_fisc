import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import './app_input_style.dart';
import './input_title.dart';
import './search_picker_sheet.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/extensions.dart';

/// How a multi-select field shows what is in it.
///
/// - [chips]: a removable chip per selection, spilling into "+N" past
///   [AppMultiSelectInput.maxVisibleChips].
/// - [labels]: the labels on one line, comma-separated and ellipsized.
/// - [count]: "3 selected" — for a field whose picks are long or many.
enum AppMultiSelectDisplay { chips, labels, count }

/// [AppDropdownInput]'s plural: the same id/label item list, any number of
/// them selected, picked in a [SearchPickerSheet] with a checkbox per row.
///
/// ```dart
/// AppMultiSelectInput<TagModel>(
///   label: 'Tags',
///   items: tags,
///   idOf: (t) => t.id,
///   labelOf: (t) => t.name,
///   selectedIds: _tagIds,
///   required: true,
///   maxSelected: 3,
///   onChanged: (ids) => setState(() => _tagIds = ids),
/// )
/// ```
///
/// The caller owns the selection — [onChanged] hands back the whole new list,
/// so the field never holds a second copy of the truth.
class AppMultiSelectInput<T> extends StatelessWidget {
  const AppMultiSelectInput({
    super.key,
    required this.label,
    required this.items,
    required this.idOf,
    required this.labelOf,
    this.onChanged,
    this.selectedIds = const [],
    this.onSelected,
    this.hint = 'Select options',
    this.enabled = true,
    this.readOnly = false,
    this.required = false,
    this.minSelected,
    this.maxSelected,
    this.validator,
    this.autovalidateMode,
    this.display = AppMultiSelectDisplay.chips,
    this.maxVisibleChips = 3,
    this.searchHint = 'Search',
    this.searchTitle,
    this.leadingOf,
    this.trailingLabelOf,
    this.filter,
    this.emptyLabel,
    this.prefixIcon,
    this.suffixIcon,
    this.labelMode,
    this.variant,
    this.type,
    this.shape,
    this.size,
  });

  final String label;
  final List<T> items;

  /// Extract the id from an item. Ids are what the selection is made of, so
  /// they must be unique across [items] — a duplicate trips an assert.
  final String Function(T item) idOf;

  /// Extract the display label from an item.
  final String Function(T item) labelOf;

  /// Called with the complete new selection, in the order the items appear in
  /// [items] — not in the order they were ticked, which no caller wants to
  /// store. Only a [readOnly] field may leave it out — one whose sheet never
  /// opens has nothing to report.
  final ValueChanged<List<String>>? onChanged;

  /// The current selection.
  final List<String> selectedIds;

  /// Called with the items themselves, alongside [onChanged].
  final ValueChanged<List<T>>? onSelected;

  final String hint;
  final bool enabled;

  /// Shows the selection at full strength but refuses to reopen the sheet —
  /// see [ReadOnlyGate]. The chips lose their delete buttons with it, since a
  /// chip that cannot be removed should not offer an X.
  final bool readOnly;

  /// Marks the label, and — unless [validator] replaces the rule — rejects an
  /// empty selection when the form validates.
  final bool required;

  /// Floor and ceiling on how many may be picked. [maxSelected] is enforced in
  /// the sheet as well: past it the unticked rows stop responding rather than
  /// letting the user pick something the form will reject.
  final int? minSelected;
  final int? maxSelected;

  /// Replaces the built-in rule entirely. Receives the selected ids.
  /// Call [AppMultiSelectInput.validate] from inside it to add a rule on top
  /// instead of dropping the required, min and max checks.
  final String? Function(List<String> ids)? validator;

  /// When the field validates itself. Null follows the config.
  final AutovalidateMode? autovalidateMode;

  final AppMultiSelectDisplay display;

  /// How many chips are drawn before the rest become a "+N" chip. Only read by
  /// [AppMultiSelectDisplay.chips].
  final int maxVisibleChips;

  final String searchHint;

  /// Heading over the sheet. Defaults to [label].
  final String? searchTitle;

  /// Optional leading widget per row in the sheet.
  final Widget Function(T item)? leadingOf;

  /// Optional dimmed text at the end of a sheet row.
  final String Function(T item)? trailingLabelOf;

  /// Replaces the sheet's default filter, a case-insensitive `contains` over
  /// [labelOf]. Returns the rows to show in the order to show them.
  final List<T> Function(List<T> items, String query)? filter;

  /// Shown in the sheet in place of the list when there is nothing to show.
  final String? emptyLabel;

  final Widget? prefixIcon;

  /// Replaces the chevron — and with it the clear button.
  final Widget? suffixIcon;

  /// Null follows [AppInputConfig.defaults].
  final AppInputLabelMode? labelMode;
  final AppInputVariant? variant;
  final AppInputType? type;
  final AppInputShape? shape;
  final AppInputSize? size;

  /// The default rule: a required field holds at least one id, and the
  /// selection sits inside [min] and [max]. Exposed so a custom [validator]
  /// can layer on top of it.
  static String? validate(
    List<String> ids, {
    bool required = false,
    int? min,
    int? max,
  }) {
    if (required && ids.isEmpty) return AppInputStyle.config.requiredMessage;
    // An empty optional field is not "fewer than min" — it is untouched, and
    // saying "pick at least 2" to someone who picked none is noise.
    if (min != null && ids.isNotEmpty && ids.length < min) {
      return 'Pick at least $min';
    }
    if (max != null && ids.length > max) return 'Pick no more than $max';
    return null;
  }

  /// The items the selection points at, in [items] order.
  List<T> get _selected => [
    for (final item in items)
      if (selectedIds.contains(idOf(item))) item,
  ];

  String? _validate(List<String> ids) {
    final rule = validator;
    return rule != null
        ? rule(ids)
        : validate(ids, required: required, min: minSelected, max: maxSelected);
  }

  Future<void> _openSheet(
    BuildContext context,
    FormFieldState<List<String>> state,
  ) async {
    final picked = await SearchPickerSheet.showMulti<T>(
      context,
      title: searchTitle ?? label,
      searchHint: searchHint,
      items: items,
      idOf: idOf,
      labelOf: labelOf,
      selectedIds: selectedIds,
      maxSelected: maxSelected,
      leadingOf: leadingOf,
      trailingLabelOf: trailingLabelOf,
      filter: filter,
      emptyLabel:
          emptyLabel ??
          (items.isEmpty
              ? 'Nothing to choose from'
              : 'Nothing matches that search'),
      variant: variant,
    );
    // Null is a dismissed sheet, which leaves the selection alone. An empty
    // list is a confirmed "none of them", which does not.
    if (picked == null) return;
    _report(picked, state);
  }

  void _report(List<T> picked, FormFieldState<List<String>> state) {
    final ids = [for (final item in picked) idOf(item)];
    // Marks the field as interacted with, so a form set to validate on
    // interaction clears its error the moment a selection lands.
    state.didChange(ids);
    onChanged?.call(ids);
    onSelected?.call(picked);
  }

  void _remove(T item, FormFieldState<List<String>> state) {
    HapticFeedback.selectionClick();
    final id = idOf(item);
    _report([
      for (final other in _selected)
        if (idOf(other) != id) other,
    ], state);
  }

  /// What sits at the end of the field: the caller's suffix, else the clear
  /// button once there is something to clear, ahead of the chevron.
  Widget? _trailing(FormFieldState<List<String>> state) {
    if (suffixIcon != null) return suffixIcon;
    if (!enabled) return null;

    const chevron = Icon(Icons.keyboard_arrow_down);
    if (selectedIds.isEmpty) return chevron;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            _report(const [], state);
          },
          tooltip: 'Clear',
          icon: const Icon(Icons.close),
        ),
        chevron,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(
      items.map(idOf).toSet().length == items.length,
      'AppMultiSelectInput<$T>: idOf returned the same id for more than one '
      'item. Ids are what the selection is made of, so they have to be unique.',
    );
    assert(
      onChanged != null || readOnly,
      'AppMultiSelectInput<$T>: a field the user can pick in needs an '
      'onChanged. Pass readOnly: true for one that only shows the selection.',
    );

    return InputFieldLayout(
      label: label,
      required: required,
      labelMode: labelMode,
      variant: variant,
      size: size,
      field: FormField<List<String>>(
        initialValue: selectedIds,
        enabled: enabled,
        autovalidateMode:
            autovalidateMode ?? AppInputStyle.config.autovalidateMode,
        // Judged on [selectedIds] rather than on the value this FormField holds:
        // the caller owns the selection, so its answer is the true one even
        // before a rebuild has reached here.
        validator: (_) => _validate(selectedIds),
        builder: (state) => ReadOnlyGate(
          readOnly: readOnly,
          child: MergeSemantics(
            child: Semantics(
              button: true,
              enabled: enabled,
              child: InkWell(
                onTap: enabled ? () => _openSheet(context, state) : null,
                borderRadius: AppConstants.borderRadius12,
                child: InputDecorator(
                  decoration:
                      AppInputStyle.decoration(
                        context,
                        variant: variant,
                        type: type,
                        shape: shape,
                        size: size,
                        label: label,
                        labelMode: labelMode,
                        required: required,
                        hint: hint,
                        prefixIcon: prefixIcon,
                        suffixIcon: _trailing(state),
                        enabled: enabled,
                      ).copyWith(
                        error: AppInputStyle.decorationErrorOrNull(
                          context,
                          state.errorText,
                          type: type,
                        ),
                      ),
                  isEmpty: selectedIds.isEmpty,
                  child: selectedIds.isEmpty ? null : _value(context, state),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _value(BuildContext context, FormFieldState<List<String>> state) {
    final accent = AppInputStyle.accentOrNull(context, variant);
    final selected = _selected;
    final valueStyle = AppInputStyle.valueStyle(
      context,
      size: size,
      variant: variant,
    );

    return switch (display) {
      AppMultiSelectDisplay.count => Text(
        '${selected.length} selected',
        style: valueStyle,
      ),
      AppMultiSelectDisplay.labels => Text(
        [for (final item in selected) labelOf(item)].join(', '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: valueStyle,
      ),
      AppMultiSelectDisplay.chips => _chips(context, selected, state, accent),
    };
  }

  Widget _chips(
    BuildContext context,
    List<T> selected,
    FormFieldState<List<String>> state,
    Color? accent,
  ) {
    final overflow = selected.length - maxVisibleChips;
    final shown = overflow > 0 ? selected.take(maxVisibleChips) : selected;

    return Wrap(
      spacing: AppConstants.space4,
      runSpacing: AppConstants.space4,
      children: [
        for (final item in shown)
          // The chip's own delete button is the shortest path to dropping one
          // pick, and it keeps the sheet for the case where several change.
          InputChip(
            label: Text(labelOf(item)),
            // Null in each of these leaves the chip to `chipTheme`; a variant
            // paints it in the same color the field around it is wearing.
            labelStyle: accent == null
                ? null
                : context.textTheme.bodySmall?.copyWith(color: accent),
            backgroundColor: accent?.withValues(
              alpha: AppInputStyle.config.fillOpacity * 2,
            ),
            side: accent == null ? null : BorderSide.none,
            visualDensity: VisualDensity.compact,
            deleteIcon: const Icon(Icons.close, size: AppConstants.iconSmall),
            deleteIconColor: accent,
            onDeleted: enabled && !readOnly ? () => _remove(item, state) : null,
          ),
        if (overflow > 0)
          Padding(
            padding: const EdgeInsets.only(top: AppConstants.space4),
            child: Text(
              '+$overflow',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
