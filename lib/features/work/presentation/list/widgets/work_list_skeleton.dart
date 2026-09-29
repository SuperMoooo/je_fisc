import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../domain/models/work_model.dart';
import 'work_card.dart';

/// Fake [WorkCard]s laid out like `WorkList`, for a skeleton to trace.
///
/// Not a skeleton by itself: `AppStatusView` wraps its `skeleton` in a
/// `Skeletonizer`, and `WorkList` does the same for its first page.
class WorkListSkeleton extends StatelessWidget {
  const WorkListSkeleton({super.key});

  /// Enough to fill a phone screen.
  static const _count = 8;

  static final _work = WorkModel(
    id: 0,
    clientName: BoneMock.name,
    address: BoneMock.address,
    startDate: DateTime(2000),
    endDate: DateTime(2000),
  );

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: AppConstants.paddingPage,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _count,
      separatorBuilder: (_, _) => const SizedBox(height: AppConstants.space8),
      itemBuilder: (_, _) => WorkCard(work: _work),
    );
  }
}
