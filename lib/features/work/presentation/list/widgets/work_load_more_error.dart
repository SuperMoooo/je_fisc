import 'package:flutter/material.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../shared/widgets/buttons/app_button.dart';

/// The row at the end of `WorkList` when a page after the first fails. The
/// works already loaded stay above it.
class WorkLoadMoreError extends StatelessWidget {
  const WorkLoadMoreError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: AppConstants.padding16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Não foi possível carregar mais obras.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.space8),
          AppButton(
            variant: AppButtonVariant.primary,
            type: AppButtonType.ghost,
            size: AppButtonSize.small,
            label: 'Tentar novamente',
            prefixIcon: Icons.refresh,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
