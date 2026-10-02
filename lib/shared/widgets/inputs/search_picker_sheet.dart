import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import './app_input_style.dart';
import './app_search_field.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/extensions.dart';

/// A bottom sheet that picks one row out of a long list, with a search field
/// pinned above it.
///
/// A dropdown menu stops being usable somewhere around thirty options, which is
/// why [AppDropdownInput] opens this once it is told `searchable: true`, and why
/// the country selector on `AppPhoneInput` — 238 rows — uses nothing else.
///
/// Generic over the row type, so callers keep their own models:
///
/// ```dart
/// final picked = await SearchPickerSheet.show<CategoryModel>(
///   context,
///   title: 'Category',
///   items: categories,
///   idOf: (item) => item.id,
///   labelOf: (item) => item.name,
///   selectedId: _categoryId,
/// );
/// ```
///
/// Resolves to the picked item, or null when the sheet is dismissed.
///
/// [showMulti] opens the same sheet with a checkbox per row and a Done button —
/// what [AppMultiSelectInput] uses. One sheet covers both because everything
/// that makes this sheet worth having (the search, the filter, opening at the
/// current selection) is the same either way.
class SearchPickerSheet<T> extends StatefulWidget {
  /// Creates the sheet. Prefer [show] or [showMulti], which open it with the
  /// modal settings a full-height searchable sheet needs.
  const SearchPickerSheet({
    super.key,
    required this.title,
    required this.items,
    required this.idOf,
    required this.labelOf,
    this.selectedId,
    this.selectedIds = const [],
    this.multiSelect = false,
    this.maxSelected,
    this.doneLabel = 'Done',
    this.searchHint = 'Search',
    this.leadingOf,
    this.trailingLabelOf,
    this.filter,
    this.emptyLabel = 'Nothing matches that search',
    this.variant,
  });

  /// Heading over the search field.
  final String title;

  /// Rows to choose from.
  final List<T> items;

  /// Extracts the id used to mark the current selection.
  final String Function(T item) idOf;

  /// Extracts the row's display text — and, unless [matches] says otherwise,
  /// the text the query is compared against.
  final String Function(T item) labelOf;

  /// The row to mark as current and to open the list scrolled to.
  final String? selectedId;

  /// The rows already ticked, when [multiSelect]. The sheet works on its own
  /// copy and reports the result once, so a dismissed sheet changes nothing.
  final List<String> selectedIds;

  /// Puts a checkbox on every row and a Done button under the list. Tapping a
  /// row toggles it instead of closing the sheet.
  final bool multiSelect;

  /// Ceiling on how many may be ticked. At the limit the unticked rows stop
  /// responding — better than letting the user pick a sixth of five and having
  /// the form refuse it afterwards. Only read when [multiSelect].
  final int? maxSelected;

  /// Copy on the confirm button. Only read when [multiSelect].
  final String doneLabel;

  /// Placeholder in the search field.
  final String searchHint;

  /// Optional leading widget per row — a flag, an avatar, an icon.
  final Widget Function(T item)? leadingOf;

  /// Optional dimmed text at the end of a row, for a secondary value like a
  /// calling code.
  final String Function(T item)? trailingLabelOf;

  /// Replaces the default filter, which is a case-insensitive `contains` over
  /// [labelOf].
  ///
  /// Returns the rows to show *in the order to show them*, so a caller can
  /// rank matches as well as select them — which is how the country picker
  /// keeps Portugal above Egypt for the query `PT`.
  final List<T> Function(List<T> items, String query)? filter;

  /// Shown in place of the list when nothing matches.
  final String emptyLabel;

  /// Null follows [AppInputConfig.defaults].
  final AppInputVariant? variant;

  /// Opens the sheet and resolves to the picked item, or null if dismissed.
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required List<T> items,
    required String Function(T item) idOf,
    required String Function(T item) labelOf,
    String? selectedId,
    String searchHint = 'Search',
    Widget Function(T item)? leadingOf,
    String Function(T item)? trailingLabelOf,
    List<T> Function(List<T> items, String query)? filter,
    String emptyLabel = 'Nothing matches that search',
    AppInputVariant? variant,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      // The sheet has to be free to grow past half the screen and to sit above
      // the keyboard the search field raises.
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SearchPickerSheet<T>(
        title: title,
        items: items,
        idOf: idOf,
        labelOf: labelOf,
        selectedId: selectedId,
        searchHint: searchHint,
        leadingOf: leadingOf,
        trailingLabelOf: trailingLabelOf,
        filter: filter,
        emptyLabel: emptyLabel,
        variant: variant,
      ),
    );
  }

  /// Opens the sheet in multi-select mode and resolves to everything ticked
  /// when Done was tapped, or null if it was dismissed.
  ///
  /// An empty list and null mean different things: the first is a deliberate
  /// "none of them", the second is "leave it as it was".
  static Future<List<T>?> showMulti<T>(
    BuildContext context, {
    required String title,
    required List<T> items,
    required String Function(T item) idOf,
    required String Function(T item) labelOf,
    List<String> selectedIds = const [],
    int? maxSelected,
    String doneLabel = 'Done',
    String searchHint = 'Search',
    Widget Function(T item)? leadingOf,
    String Function(T item)? trailingLabelOf,
    List<T> Function(List<T> items, String query)? filter,
    String emptyLabel = 'Nothing matches that search',
    AppInputVariant? variant,
  }) {
    return showModalBottomSheet<List<T>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SearchPickerSheet<T>(
        title: title,
        items: items,
        idOf: idOf,
        labelOf: labelOf,
        selectedIds: selectedIds,
        multiSelect: true,
        maxSelected: maxSelected,
        doneLabel: doneLabel,
        searchHint: searchHint,
        leadingOf: leadingOf,
        trailingLabelOf: trailingLabelOf,
        filter: filter,
        emptyLabel: emptyLabel,
        variant: variant,
      ),
    );
  }

  @override
  State<SearchPickerSheet<T>> createState() => _SearchPickerSheetState<T>();
}

class _SearchPickerSheetState<T> extends State<SearchPickerSheet<T>> {
  late final ScrollController _scrollController = ScrollController(
    initialScrollOffset: _initialOffset,
  );
  String _query = '';

  /// The sheet's own copy of a multi-select selection: it is reported once, on
  /// Done, so backing out of the sheet leaves the caller's list untouched.
  late final Set<String> _picked = {...widget.selectedIds};

  /// Opens the list already showing the current selection, so a picker over a
  /// long table doesn't start hundreds of rows away from the answer.
  ///
  /// Exact rather than estimated because the rows are a fixed [_rowHeight].
  double get _initialOffset {
    // In multi-select the first tick is the one to open at — it is where the
    // user was working, and later ones are usually near it.
    final selectedId =
        widget.selectedId ??
        (widget.selectedIds.isEmpty ? null : widget.selectedIds.first);
    if (selectedId == null) return 0;
    final index = widget.items.indexWhere(
      (item) => widget.idOf(item) == selectedId,
    );
    return index <= 0 ? 0 : index * _rowHeight;
  }

  /// True once as many rows are ticked as [SearchPickerSheet.maxSelected]
  /// allows.
  bool get _atLimit =>
      widget.maxSelected != null && _picked.length >= widget.maxSelected!;

  /// Everything ticked, in [SearchPickerSheet.items] order rather than in the
  /// order it was tapped — which is the order a caller wants to store.
  List<T> get _pickedItems => [
    for (final item in widget.items)
      if (_picked.contains(widget.idOf(item))) item,
  ];

  void _toggle(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_picked.remove(id)) _picked.add(id);
    });
  }

  List<T> get _filtered {
    final filter = widget.filter;
    if (filter != null) return filter(widget.items, _query);

    final needle = _query.trim().toLowerCase();
    if (needle.isEmpty) return widget.items;
    return [
      for (final item in widget.items)
        if (widget.labelOf(item).toLowerCase().contains(needle)) item,
    ];
  }

  void _onQueryChanged(String query) {
    setState(() => _query = query);
    // The previous offset means nothing against a freshly filtered list, and
    // may well be past its end.
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final mediaQuery = MediaQuery.of(context);
    final accent = AppInputStyle.accentOf(context, widget.variant);
    final rows = _filtered;

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Material(
        color: theme.colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.radius24),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: mediaQuery.size.height * _maxHeightFactor,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: AppConstants.padding16,
                  child: Column(
                    children: [
                      Text(
                        widget.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.space12),
                      AppSearchField(
                        hint: widget.searchHint,
                        autofocus: true,
                        variant: widget.variant,
                        onChanged: _onQueryChanged,
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: theme.colorScheme.outlineVariant),
                Flexible(
                  child: rows.isEmpty
                      ? Padding(
                          padding: AppConstants.padding24,
                          child: Text(
                            widget.emptyLabel,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          // A fixed extent is what makes _initialOffset exact,
                          // and it keeps a 238-row list cheap to scroll.
                          itemExtent: _rowHeight,
                          padding: EdgeInsets.zero,
                          itemCount: rows.length,
                          itemBuilder: (context, index) {
                            final item = rows[index];
                            final id = widget.idOf(item);
                            final selected = widget.multiSelect
                                ? _picked.contains(id)
                                : id == widget.selectedId;
                            final trailing = widget.trailingLabelOf?.call(item);
                            // Past the ceiling only the ticked rows still
                            // answer: offering a pick the caller has to throw
                            // away is worse than showing it can't be made.
                            final enabled =
                                !widget.multiSelect || selected || !_atLimit;

                            return ListTile(
                              enabled: enabled,
                              selected: selected,
                              selectedColor: accent,
                              leading: widget.leadingOf?.call(item),
                              title: Text(
                                widget.labelOf(item),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: selected
                                    ? const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      )
                                    : null,
                              ),
                              trailing: _rowTrailing(
                                theme: theme,
                                accent: accent,
                                trailingLabel: trailing,
                                selected: selected,
                                enabled: enabled,
                                id: id,
                              ),
                              onTap: enabled
                                  ? () {
                                      if (widget.multiSelect) {
                                        _toggle(id);
                                        return;
                                      }
                                      HapticFeedback.selectionClick();
                                      Navigator.pop(context, item);
                                    }
                                  : null,
                            );
                          },
                        ),
                ),
                if (widget.multiSelect) _confirmBar(theme, accent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The end of a row: its secondary label, and in multi-select the checkbox
  /// that says whether it is in.
  Widget? _rowTrailing({
    required ThemeData theme,
    required Color accent,
    required String? trailingLabel,
    required bool selected,
    required bool enabled,
    required String id,
  }) {
    final label = trailingLabel == null
        ? null
        : Text(
            trailingLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: selected ? accent : theme.colorScheme.onSurfaceVariant,
            ),
          );

    if (!widget.multiSelect) return label;

    final checkbox = Checkbox(
      value: selected,
      activeColor: accent,
      // The whole row is the target — the box only has to report the state, and
      // a second tap handler here would double the haptics.
      onChanged: enabled ? (_) => _toggle(id) : null,
    );

    if (label == null) return checkbox;
    return Row(mainAxisSize: MainAxisSize.min, children: [label, checkbox]);
  }

  /// The bar under a multi-select list: how many are in, and the button that
  /// commits them.
  Widget _confirmBar(ThemeData theme, Color accent) {
    final max = widget.maxSelected;
    return Container(
      padding: AppConstants.padding16,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        spacing: AppConstants.space12,
        children: [
          Expanded(
            child: Text(
              max == null
                  ? '${_picked.length} selected'
                  : '${_picked.length} of $max selected',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: accent),
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context, _pickedItems);
            },
            child: Text(widget.doneLabel),
          ),
        ],
      ),
    );
  }
}

/// Rows are a fixed height so the list can be opened at an exact offset.
const double _rowHeight = 56;

/// How much of the screen the sheet may take before its list scrolls.
const double _maxHeightFactor = 0.85;
