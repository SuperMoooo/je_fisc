import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/extensions.dart';

/// Fill treatment of the sheet's close button.
///
/// Mirrors `AppIconButtonType`'s naming so it reads like the rest of the kit.
/// It is redeclared here rather than imported because this widget ships with
/// `moarch init` and AppIconButton does not — an init widget can only lean on
/// other init widgets.
enum AppSheetCloseType { filled, tonal, outlined, ghost }

/// The standard inside of a bottom sheet: a rounded surface panel with a drag
/// handle (grabber) at the top, an optional [title], an optional close button,
/// and your [child].
/// Pass this as the `child` to `AppBottomModals.showAppBottomModal`.
class AppBottomSheetScaffold extends StatelessWidget {
  const AppBottomSheetScaffold({
    super.key,
    required this.child,
    this.title,
    this.showHandle = true,
    this.padding = AppConstants.paddingPage,
    this.titleAlign = TextAlign.center,
    this.handleWidth = 40,
    this.handleHeight = 4,
    this.handleColor,
    this.showClose = false,
    this.onClose,
    this.closeIcon = Icons.close,
    this.closeType = AppSheetCloseType.tonal,
    this.closeColor,
  });

  final Widget child;
  final String? title;
  final bool showHandle;
  final EdgeInsetsGeometry padding;

  /// Centered reads as a modal, [TextAlign.start] as a panel. Pick one per app
  /// and keep to it.
  final TextAlign titleAlign;

  final double handleWidth;
  final double handleHeight;

  /// Defaults to a muted `onSurfaceVariant`. Worth overriding only when the
  /// sheet sits on a colored surface.
  final Color? handleColor;

  /// Shows a close button in the sheet's top corner. The drag handle already
  /// says "dismissable" — add this when the sheet is tall enough that the
  /// handle scrolls out of reach, or when dismissal needs to be obvious.
  final bool showClose;

  /// Overrides the default `Navigator.maybePop` — e.g. to confirm unsaved work.
  final VoidCallback? onClose;

  final IconData closeIcon;

  /// How the close button wears [closeColor]. Tonal gives the soft grey circle
  /// most sheets want; [AppSheetCloseType.ghost] is a bare glyph.
  final AppSheetCloseType closeType;

  /// Defaults to `onSurfaceVariant` — a close button is chrome, not an action,
  /// so it stays neutral unless you say otherwise.
  final Color? closeColor;

  /// Matches AppIconButton's `small` tap target, so a sheet close and an icon
  /// button elsewhere in the app are the same size.
  static const double _closeDimension = 32;
  static const double _closeTonalOpacity = 0.12;
  static const double _closeBorderWidth = 1.5;
  static const double _handleOpacity = 0.4;

  Widget _buildClose(BuildContext context, ThemeData theme) {
    final accent = closeColor ?? theme.colorScheme.onSurfaceVariant;
    final (background, foreground) = switch (closeType) {
      AppSheetCloseType.filled => (accent, theme.colorScheme.surface),
      AppSheetCloseType.tonal => (
        Color.alphaBlend(
          accent.withValues(alpha: _closeTonalOpacity),
          theme.colorScheme.surface,
        ),
        accent,
      ),
      AppSheetCloseType.outlined ||
      AppSheetCloseType.ghost => (Colors.transparent, accent),
    };

    return Tooltip(
      message: MaterialLocalizations.of(context).closeButtonTooltip,
      child: Material(
        color: background,
        clipBehavior: Clip.antiAlias,
        shape: CircleBorder(
          side: closeType == AppSheetCloseType.outlined
              ? BorderSide(color: accent, width: _closeBorderWidth)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            if (onClose != null) {
              onClose!();
            } else {
              Navigator.maybePop(context);
            }
          },
          child: SizedBox.square(
            dimension: _closeDimension,
            child: Icon(
              closeIcon,
              size: AppConstants.iconSmall,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showHandle)
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: AppConstants.space12),
                  width: handleWidth,
                  height: handleHeight,
                  decoration: BoxDecoration(
                    color:
                        handleColor ??
                        theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: _handleOpacity,
                        ),
                    borderRadius: AppConstants.borderRadiusFull,
                  ),
                ),
              ),
            Padding(
              padding: padding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (title != null || showClose) ...[
                    // A Stack rather than a Row: it keeps a centered title
                    // centered on the sheet instead of on the space left over
                    // beside the close button.
                    Stack(
                      alignment: AlignmentDirectional.centerEnd,
                      children: [
                        if (title != null)
                          Padding(
                            // Reserve the close button's width on both sides so
                            // a centered title doesn't drift left to avoid it.
                            padding: EdgeInsets.symmetric(
                              horizontal: showClose ? _closeDimension : 0,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: Text(
                                title!,
                                style: theme.textTheme.titleLarge,
                                textAlign: titleAlign,
                              ),
                            ),
                          ),
                        if (showClose) _buildClose(context, theme),
                      ],
                    ),
                    const SizedBox(height: AppConstants.space16),
                  ],
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
