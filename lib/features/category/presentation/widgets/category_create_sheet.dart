import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:je_fisc/core/constants/app_constants.dart';
import 'package:je_fisc/core/utils/extensions.dart';
import 'package:je_fisc/shared/widgets/buttons/app_button.dart';
import 'package:je_fisc/shared/widgets/inputs/app_input.dart';
import 'package:je_fisc/shared/widgets/overlays/app_bottom_modals.dart';
import 'package:je_fisc/shared/widgets/overlays/app_bottom_sheet_scaffold.dart';

/// Asks for a new category's name. Pops the trimmed name, or null when
/// dismissed — saving it is the caller's bloc's job, so the sheet needs none.
class CategoryCreateSheet extends StatefulWidget {
  const CategoryCreateSheet({super.key});

  static Future<String?> show() => AppBottomModals().showAppBottomModal<String>(
    child: const CategoryCreateSheet(),
  );

  @override
  State<CategoryCreateSheet> createState() => _CategoryCreateSheetState();
}

class _CategoryCreateSheetState extends State<CategoryCreateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtr = TextEditingController();

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
        title: 'Nova Categoria',
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
                label: 'Adicionar',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
