import 'package:flutter/material.dart';
import '../../../config/theme/app_status_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/extensions.dart';

/// Status role of an [AppTag].
enum AppTagStatus { neutral, success, warning, error, info }

/// A small status pill — "Active", "Pending", "Failed". The color comes from
/// [status] and the fill is a soft tint of it, so several tags sit calmly
/// together in a list.
class AppTag extends StatelessWidget {
  const AppTag({
    super.key,
    required this.label,
    this.status = AppTagStatus.neutral,
    this.icon,
  });

  final String label;
  final AppTagStatus status;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final color = switch (status) {
      AppTagStatus.neutral => theme.colorScheme.onSurfaceVariant,
      AppTagStatus.success => AppStatusColors.of(theme).success,
      AppTagStatus.warning => AppStatusColors.of(theme).warning,
      AppTagStatus.error => theme.colorScheme.error,
      AppTagStatus.info => AppStatusColors.of(theme).info,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.space8,
        vertical: AppConstants.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppConstants.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: AppConstants.space4),
          ],
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
