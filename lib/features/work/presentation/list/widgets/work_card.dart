import 'package:flutter/material.dart';
import 'package:je_fisc/core/constants/app_constants.dart';
import 'package:je_fisc/shared/widgets/cards/app_card.dart';

import '../../../../../core/utils/extensions.dart';
import '../../../domain/models/work_model.dart';

/// One work in the list: client, address, and the dates it runs.
class WorkCard extends StatelessWidget {
  const WorkCard({super.key, required this.work, this.onTap});

  final WorkModel work;

  /// Null draws the card without a chevron, as nothing to open.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textStyle = context.textTheme;
    return AppCard(
      onTap: onTap,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(work.clientName, style: textStyle.titleLarge),
        subtitle: Column(
          crossAxisAlignment: .start,
          mainAxisSize: .min,
          children: [
            Row(
              spacing: AppConstants.space4,
              mainAxisSize: .min,
              children: [
                const Icon(Icons.location_on_outlined),
                Text(work.address),
              ],
            ),
            Row(
              spacing: AppConstants.space4,
              mainAxisSize: .min,
              children: [
                const Icon(Icons.date_range_outlined),
                Text(
                  '${work.startDate.formattedDate} - ${work.endDate?.formattedDate ?? "??/??/????"}',
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(
          Icons.chevron_right,
          size: AppConstants.iconMedium,
        ),
      ),
    );
  }
}
