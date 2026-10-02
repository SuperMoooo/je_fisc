import 'package:flutter/material.dart';

/// Wraps [child] with a notification [Badge] — a small count or dot in the
/// top-end corner. Pass [count] for a number (hidden when 0), or leave it null
/// with [showDot] for a plain presence dot.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.child,
    this.count,
    this.showDot = false,
    this.color,
  });

  final Widget child;
  final int? count;
  final bool showDot;

  /// Null leaves the badge to `badgeTheme`, which is where an app changes what
  /// all of its badges look like.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (count == null && !showDot) return child;
    if (count != null && count! <= 0) return child;

    if (count == null) {
      return Badge(backgroundColor: color, smallSize: 8, child: child);
    }

    return Badge(
      backgroundColor: color,
      label: Text(count! > 99 ? '99+' : '$count'),
      child: child,
    );
  }
}
