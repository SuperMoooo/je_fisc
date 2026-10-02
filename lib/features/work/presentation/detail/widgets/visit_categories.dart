import 'package:flutter/widgets.dart';
import 'package:je_fisc/core/constants/app_constants.dart';
import 'package:je_fisc/features/category/domain/models/category_model.dart';
import 'package:je_fisc/shared/widgets/indicators/app_tag.dart';

/// A visit's categories as a wrapping row of tags. Draws nothing for none.
class VisitCategories extends StatelessWidget {
  const VisitCategories({super.key, required this.categories});

  final List<CategoryModel> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppConstants.space8,
      runSpacing: AppConstants.space8,
      children: [
        for (final category in categories) AppTag(label: category.name),
      ],
    );
  }
}
