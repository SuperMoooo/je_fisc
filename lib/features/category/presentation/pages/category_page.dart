import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/injector.dart';
import '../blocs/category_bloc.dart';
import '../blocs/category_event.dart';
import '../views/category_view.dart';

/// Owns the bloc: leaving the route closes it.
class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CategoryBloc>()..add(const CategoryStarted()),
      child: const CategoryView(),
    );
  }
}
