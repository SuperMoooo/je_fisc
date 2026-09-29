import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/extensions.dart';

/// Fill treatment of [AppCard].
/// - [elevated]: soft shadow, raised off the surface.
/// - [filled]: sits on a tonal surface, no border (the default).
/// - [outlined]: flat with a hairline border.
enum AppCardType { elevated, filled, outlined }

/// A themed surface container. Provide [onTap] to make the whole card tappable.
///
/// Its surface is `cardTheme.color` from `config/theme/app_theme.dart` — the
/// same color `AppInputStyle` fills a field with — so a card and an input
/// standing next to each other read as one surface, and moving the theme moves
/// both.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.type = AppCardType.filled,
    this.padding = AppConstants.padding16,
    this.margin,
    this.borderColor,
    this.onTap,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final AppCardType type;

  /// Inset between the card's edge and its content.
  final EdgeInsetsGeometry padding;

  /// Inset around the outside of the card — space between it and whatever it
  /// sits next to. Null is none. It stays outside the surface, so the border,
  /// the shadow and the tap ripple all stop at the card's edge.
  final EdgeInsetsGeometry? margin;

  /// Color of the card's hairline border. On [AppCardType.outlined] it stands
  /// in for the default [ColorScheme.outlineVariant]; on the other two it adds
  /// a border they do not otherwise draw — a filled card ringed in the error
  /// color to mark an invalid section, say. Null leaves each type as it is.
  final Color? borderColor;

  final VoidCallback? onTap;

  /// How the child is clipped to the card's rounded corners. Defaults to
  /// [Clip.antiAlias] so an interactive child (e.g. an AppListTile with
  /// [padding] set to [EdgeInsets.zero]) keeps its ripple inside the corners.
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final cardTheme = theme.cardTheme;

    // `cardTheme` decides what a card is made of, so a project restyles its
    // cards there rather than here. The fallbacks cover one that has not
    // themed cards at all.
    final surface = cardTheme.color ?? theme.colorScheme.surfaceContainerLowest;
    final shadow = cardTheme.shadowColor ?? Colors.black;

    // Only a rounded rectangle has a BorderRadius to hand the ripple and the
    // clip; a stadium or a beveled border does not, so the kit's own token
    // stands in for those rather than guessing at one.
    final shape = cardTheme.shape;
    final radius = shape is RoundedRectangleBorder
        ? shape.borderRadius.resolve(Directionality.of(context))
        : AppConstants.borderRadius16;

    // Outlined always draws a border; the other two only once asked for one.
    final border = borderColor == null && type != AppCardType.outlined
        ? null
        : Border.all(color: borderColor ?? theme.colorScheme.outlineVariant);

    final decoration = switch (type) {
      AppCardType.elevated => BoxDecoration(
          color: surface,
          borderRadius: radius,
          border: border,
          boxShadow: [
            BoxShadow(
              color: shadow.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      AppCardType.filled => BoxDecoration(
          color: surface,
          borderRadius: radius,
          border: border,
        ),
      AppCardType.outlined => BoxDecoration(
          color: Colors.transparent,
          borderRadius: radius,
          border: border,
        ),
    };

    final content = Container(
      clipBehavior: clipBehavior,
      decoration: decoration,
      child: Padding(padding: padding, child: child),
    );

    // A tappable card is a button wearing a container; without the role a
    // screen reader reads its contents and never offers the tap.
    final card = onTap == null
        ? content
        : Semantics(
            button: true,
            child: InkWell(
              borderRadius: radius,
              onTap: () {
                HapticFeedback.selectionClick();
                onTap!();
              },
              child: content,
            ),
          );

    if (margin == null) return card;
    return Padding(padding: margin!, child: card);
  }
}
