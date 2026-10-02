import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/extensions.dart';

/// A settings/menu row: an optional leading widget (e.g. AppLeadingIcon), a
/// title with optional subtitle, and an optional trailing widget (a value
/// Text, an AppSwitch, a chevron...). Tapping anywhere fires [onTap].
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showChevron = false,
    this.danger = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Appends a trailing chevron when [trailing] is null - the usual "drills
  /// into another screen" affordance.
  final bool showChevron;

  /// Tints the title in the error color, for destructive rows like
  /// "Delete account" / "Log out".
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    // A hand-built row rather than a Material ListTile, so it has to read
    // `listTileTheme` itself — otherwise a project sets its row inset there and
    // watches nothing move.
    final tileTheme = theme.listTileTheme;
    final titleColor = danger
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;

    Widget? resolvedTrailing = trailing;
    if (resolvedTrailing == null && showChevron) {
      resolvedTrailing = Icon(
        Icons.chevron_right,
        color: tileTheme.iconColor ?? theme.colorScheme.onSurfaceVariant,
        size: AppConstants.iconMedium,
      );
    }

    final row = InkWell(
      borderRadius: AppConstants.borderRadius12,
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: Padding(
        padding:
            tileTheme.contentPadding ??
            const EdgeInsets.symmetric(
              horizontal: AppConstants.space12,
              vertical: AppConstants.space12,
            ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppConstants.space12),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    softWrap: true,
                    maxLines: 2,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: titleColor,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (resolvedTrailing != null) ...[
              const SizedBox(width: AppConstants.space12),
              resolvedTrailing,
            ],
          ],
        ),
      ),
    );

    // Merged so the title and its subtitle are one stop rather than two. The
    // button role is only claimed when there is a tap to offer: an untapped
    // row nested in an AppCardTile would otherwise plant a second, contrary
    // node inside the card that actually takes the tap.
    return MergeSemantics(
      child: onTap == null ? row : Semantics(button: true, child: row),
    );
  }
}
