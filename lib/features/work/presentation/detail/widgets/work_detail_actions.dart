import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/router/app_router.dart';
import '../../../../../config/router/app_routes.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../shared/widgets/buttons/app_button.dart';
import '../../../../../shared/widgets/buttons/edit_delete_actions.dart';
import '../../../../../shared/widgets/overlays/app_confirm_dialog.dart';
import '../../../../../shared/widgets/overlays/app_dialogs.dart';
import '../blocs/work_detail_bloc.dart';
import '../blocs/work_detail_event.dart';

/// The detail screen's app bar actions: edit the work, or delete it with its
/// visits. Hidden until the work has loaded.
class WorkDetailActions extends StatelessWidget {
  const WorkDetailActions({super.key});

  Future<void> _edit(BuildContext context, int workId) async {
    final bloc = context.read<WorkDetailBloc>();
    final saved = await appRouter.push<bool>(AppRoutes.editWorkOf(workId));
    if (saved == true) bloc.add(WorkDetailStarted(workId: workId));
  }

  Future<void> _delete(BuildContext context) async {
    final bloc = context.read<WorkDetailBloc>();
    final confirmed = await AppConfirmDialog.show(
      AppDialogs(),
      title: 'Eliminar obra?',
      message:
          'A obra, as suas visitas e todas as fotografias serão eliminadas.',
      icon: Icons.delete_outline,
      variant: AppButtonVariant.danger,
      confirmLabel: 'Eliminar',
    );
    if (confirmed) bloc.add(const WorkDetailDeleted());
  }

  @override
  Widget build(BuildContext context) {
    final workId = context.select<WorkDetailBloc, int?>(
      (bloc) => bloc.state.work?.id,
    );
    if (workId == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: AppConstants.space8),
      child: EditDeleteActions(
        onEdit: () => _edit(context, workId),
        onDelete: () => _delete(context),
      ),
    );
  }
}
