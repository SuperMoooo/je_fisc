import 'package:flutter/material.dart';
import 'package:je_fisc/core/constants/app_constants.dart';
import 'package:je_fisc/features/category/domain/models/category_model.dart';
import 'package:je_fisc/shared/widgets/cards/app_card.dart';
import 'package:je_fisc/shared/widgets/lists/app_list_tile.dart';

/// The categories as one card of rows. Shared by the view and its skeleton,
/// so the shimmer has the shape of what loads.
class CategoryList extends StatelessWidget {
  const CategoryList({super.key, required this.categories});

  final List<CategoryModel> categories;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppConstants.paddingPage,
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < categories.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                AppListTile(
                  leading: const Icon(Icons.label_outline),
                  title: categories[i].name,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
