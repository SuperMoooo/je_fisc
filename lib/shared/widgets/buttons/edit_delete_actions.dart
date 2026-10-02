import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import 'app_icon_button.dart';

/// A row's edit and delete buttons, side by side — the trailing of a list
/// tile, the corner of a card. A null callback leaves its button out.
class EditDeleteActions extends StatelessWidget {
  const EditDeleteActions({super.key, this.onEdit, this.onDelete});

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppConstants.space4,
      children: [
        if (onEdit != null)
          AppIconButton(
            icon: Icons.edit_outlined,
            tooltip: 'Editar',
            size: AppIconButtonSize.small,
            onPressed: onEdit,
          ),
        if (onDelete != null)
          AppIconButton(
            icon: Icons.delete_outline,
            tooltip: 'Eliminar',
            variant: AppIconButtonVariant.danger,
            size: AppIconButtonSize.small,
            onPressed: onDelete,
          ),
      ],
    );
  }
}
