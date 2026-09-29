import 'package:flutter/material.dart';
import '../cards/app_card.dart';
import 'app_list_tile.dart';

/// An [AppListTile] on its own [AppCard] surface — a standalone, card-backed
/// row. Saves nesting the two by hand every time you want a single tappable
/// row that isn't part of a larger list. The whole card is the tap target.
class AppCardTile extends StatelessWidget {
  const AppCardTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showChevron = false,
    this.danger = false,
    this.cardType = AppCardType.filled,
    this.margin,
    this.borderColor,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Appends a trailing chevron when [trailing] is null — the usual "drills
  /// into another screen" affordance.
  final bool showChevron;

  /// Tints the title in the error color, for destructive rows.
  final bool danger;

  /// Surface treatment of the enclosing card.
  final AppCardType cardType;

  /// Inset around the outside of the card — space between this row and the one
  /// next to it, when a stack of these is standing in for a list. Null is none.
  final EdgeInsetsGeometry? margin;

  /// Color of the card's border. See [AppCard.borderColor]: it overrides the
  /// hairline on an outlined card, and gives a filled or elevated one a border
  /// it would not otherwise draw.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    // onTap lives on the card so the whole surface is the tap target; the
    // tile stays passive (its padding still shapes the content).
    return AppCard(
      type: cardType,
      padding: EdgeInsets.zero,
      margin: margin,
      borderColor: borderColor,
      onTap: onTap,
      child: AppListTile(
        title: title,
        subtitle: subtitle,
        leading: leading,
        trailing: trailing,
        showChevron: showChevron,
        danger: danger,
      ),
    );
  }
}
