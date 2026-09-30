import 'package:flutter/material.dart';

import '../../../../../core/utils/extensions.dart';
import '../../../../../shared/widgets/lists/app_card_tile.dart';
import '../../../domain/models/work_model.dart';

/// One work in the list: client, address, and the dates it runs.
class WorkCard extends StatelessWidget {
  const WorkCard({super.key, required this.work, this.onTap});

  final WorkModel work;

  /// Null draws the card without a chevron, as nothing to open.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCardTile(
      title: work.clientName,
      subtitle:
          '${work.address}\n'
          '${work.startDate.formattedDate} - ${work.endDate?.formattedDate ?? "??/??/????"}',
      showChevron: onTap != null,
      onTap: onTap,
    );
  }
}
