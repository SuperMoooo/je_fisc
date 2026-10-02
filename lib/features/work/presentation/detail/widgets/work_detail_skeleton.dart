import 'package:flutter/widgets.dart';
import 'package:je_fisc/core/constants/app_constants.dart';
import 'package:je_fisc/features/category/domain/models/category_model.dart';
import 'package:je_fisc/features/work/domain/models/visit_model.dart';
import 'package:je_fisc/features/work/domain/models/visit_picture_model.dart';
import 'package:je_fisc/features/work/presentation/detail/widgets/visit_card.dart';
import 'package:skeletonizer/skeletonizer.dart';

class WorkDetailSkeleton extends StatelessWidget {
  const WorkDetailSkeleton({super.key});

  static const _count = 8;

  static final _visit = VisitModel(
    id: 0,
    workId: 0,
    date: DateTime(2000),
    pictures: [VisitPictureModel.empty()],
    categories: [CategoryModel(id: 0, name: BoneMock.subtitle)],
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: AppConstants.space12,
      children: [
        Expanded(
          child: ListView.separated(
            padding: AppConstants.paddingPage,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _count,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppConstants.space8),
            itemBuilder: (_, _) => VisitCard(visit: _visit),
          ),
        ),
      ],
    );
  }
}
