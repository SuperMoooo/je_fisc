import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:je_fisc/core/constants/app_constants.dart';
import 'package:je_fisc/core/utils/extensions.dart';
import 'package:je_fisc/shared/widgets/buttons/app_button.dart';
import 'package:je_fisc/shared/widgets/inputs/app_input.dart';
import 'package:je_fisc/shared/widgets/overlays/app_bottom_modals.dart';
import 'package:je_fisc/shared/widgets/overlays/app_bottom_sheet_scaffold.dart';

/// Asks for a category's name — a new one, or a new name for an existing one
/// when [initialName] is given. Pops the trimmed name, or null when
/// dismissed — saving it is the caller's bloc's job, so the sheet needs none.
class CategoryCreateSheet extends StatefulWidget {
  const CategoryCreateSheet({super.key, this.initialName});

  /// The name being edited; null to add a category.
  final String? initialName;

  static Future<String?> show({String? initialName}) =>
      AppBottomModals().showAppBottomModal<String>(
        child: CategoryCreateSheet(initialName: initialName),
      );

  @override
  State<CategoryCreateSheet> createState() => _CategoryCreateSheetState();
}

class _CategoryCreateSheetState extends State<CategoryCreateSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtr = TextEditingController(text: widget.initialName);

  bool get _isEditing => widget.initialName != null;

  @override
  void dispose() {
    _nameCtr.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.isValid) return;
    context.pop(_nameCtr.trimmed);
  }

  @override
  Widget build(BuildContext context) {
    // Lifts the sheet over the keyboard the field opens.
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AppBottomSheetScaffold(
        title: _isEditing ? 'Editar Categoria' : 'Nova Categoria',
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: AppConstants.space16,
            children: [
              AppInput(
                label: 'Nome',
                required: true,
                autoFocus: true,
                controller: _nameCtr,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              AppButton(
                variant: AppButtonVariant.primary,
                label: _isEditing ? 'Guardar' : 'Adicionar',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
