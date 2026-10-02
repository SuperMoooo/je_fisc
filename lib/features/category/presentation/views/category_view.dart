import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/app_status_view.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/overlays/app_confirm_dialog.dart';
import '../../../../shared/widgets/overlays/app_dialogs.dart';
import '../../domain/models/category_model.dart';
import '../../../../shared/widgets/overlays/app_toast.dart';
import '../blocs/category_bloc.dart';
import '../blocs/category_event.dart';
import '../blocs/category_state.dart';
import '../widgets/category_create_sheet.dart';
import '../widgets/category_list.dart';
import '../widgets/category_skeleton.dart';

/// The categories visits are tagged with, and the way to add one.
class CategoryView extends StatelessWidget {
  const CategoryView({super.key});

  Future<void> _create(BuildContext context) async {
    final bloc = context.read<CategoryBloc>();
    final name = await CategoryCreateSheet.show();
    if (name != null) bloc.add(CategoryCreated(name));
  }

  Future<void> _rename(BuildContext context, CategoryModel category) async {
    final bloc = context.read<CategoryBloc>();
    final name = await CategoryCreateSheet.show(initialName: category.name);
    if (name != null && name != category.name) {
      bloc.add(CategoryRenamed(category, name));
    }
  }

  Future<void> _delete(BuildContext context, CategoryModel category) async {
    final bloc = context.read<CategoryBloc>();
    final confirmed = await AppConfirmDialog.show(
      AppDialogs(),
      title: 'Eliminar categoria?',
      message: '"${category.name}" será eliminada.',
      icon: Icons.delete_outline,
      variant: AppButtonVariant.danger,
      confirmLabel: 'Eliminar',
    );
    if (confirmed) bloc.add(CategoryDeleted(category));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorias')),
      body: BlocConsumer<CategoryBloc, CategoryState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage ||
            previous.successMessage != current.successMessage,
        listener: (context, state) {
          final error = state.errorMessage;
          if (error != null) AppToast.error(context, error);

          final success = state.successMessage;
          if (success != null) AppToast.success(context, success);
        },
        builder: (context, state) => AppStatusView(
          status: state.status,
          message: state.errorMessage,
          isEmpty: state.categories.isEmpty,
          emptyTitle: 'Sem categorias',
          emptyMessage: 'As categorias que adicionar aparecem aqui.',
          emptyIcon: Icons.label_outline,
          onRetry: () =>
              context.read<CategoryBloc>().add(const CategoryStarted()),
          skeleton: (context) => const CategorySkeleton(),
          builder: (context) => CategoryList(
            categories: state.categories,
            onEdit: (category) => _rename(context, category),
            onDelete: (category) => _delete(context, category),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_circle_outline),
        onPressed: () => _create(context),
        label: const Text('Nova Categoria'),
      ),
    );
  }
}
