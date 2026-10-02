import 'package:flutter/material.dart';

import '../buttons/app_icon_button.dart';
import './app_input_style.dart';

/// A search field: leading search icon, plus a clear button that appears only
/// once there is something to clear.
///
/// Wire [onChanged] straight to your filter for a local list. For a remote
/// search, debounce the event rather than the callback: pass an
/// `EventTransformer` to the `on<...>` that runs the query — the bloc your
/// feature was generated with carries the sketch.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.hint = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.variant,
    this.type,
    this.shape,
    this.size,
    this.autofocus = false,
    this.enabled = true,
    this.searchIcon = Icons.search,
    this.clearIcon = Icons.close,
    this.clearVariant = AppIconButtonVariant.primary,
    this.clearType = AppIconButtonType.ghost,
    this.clearShape = AppIconButtonShape.circle,
  });

  /// Optional external controller — pass one to read or clear the query from
  /// outside. When omitted, the field owns (and disposes) its own.
  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final AppInputVariant? variant;
  final AppInputType? type;
  final AppInputShape? shape;
  final AppInputSize? size;
  final bool autofocus;
  final bool enabled;

  /// The leading icon. `Icons.search` reads as "find"; swap it for
  /// `Icons.filter_list` when the field narrows a list you're already looking
  /// at.
  final IconData searchIcon;

  final IconData clearIcon;
  final AppIconButtonVariant clearVariant;

  /// How the clear button wears its color. [AppIconButtonType.tonal] turns it
  /// into a small filled chip, which is easier to hit on a busy toolbar.
  final AppIconButtonType clearType;
  final AppIconButtonShape clearShape;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();

  /// Only dispose what this widget created — an injected controller belongs to
  /// the caller and may well outlive the field.
  late final bool _ownsController = widget.controller == null;

  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  /// Rebuilds only when the clear button has to appear or disappear, not on
  /// every keystroke.
  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.search,
      style: AppInputStyle.textStyle(context, size: widget.size),
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      decoration: AppInputStyle.decoration(
        context,
        variant: widget.variant,
        type: widget.type,
        shape: widget.shape,
        size: widget.size,
        hint: widget.hint,
        enabled: widget.enabled,
        prefixIcon: Icon(widget.searchIcon),
        suffixIcon: _hasText
            ? AppIconButton(
                icon: widget.clearIcon,
                onPressed: _clear,
                variant: widget.clearVariant,
                type: widget.clearType,
                shape: widget.clearShape,
                size: AppIconButtonSize.small,
                tooltip: 'Clear',
              )
            : null,
      ),
    );
  }
}
