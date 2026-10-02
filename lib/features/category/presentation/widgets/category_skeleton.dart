import 'package:flutter/material.dart';

import '../blocs/category_state.dart';
import 'category_list.dart';

/// The Category screen while its first load runs: the same list, drawn from
/// [CategoryState.placeholder] for the view's Skeletonizer to shimmer.
class CategorySkeleton extends StatelessWidget {
  const CategorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return CategoryList(categories: CategoryState.placeholder.categories);
  }
}
