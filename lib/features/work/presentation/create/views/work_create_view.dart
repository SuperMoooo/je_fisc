import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:je_fisc/config/router/app_router.dart';
import 'package:je_fisc/config/router/app_routes.dart';
import 'package:je_fisc/core/utils/extensions.dart';
import 'package:je_fisc/features/work/domain/models/work_model.dart';
import 'package:je_fisc/features/work/presentation/create/blocs/work_create_bloc.dart';
import 'package:je_fisc/features/work/presentation/create/blocs/work_create_event.dart';
import 'package:je_fisc/features/work/presentation/create/blocs/work_create_state.dart';
import 'package:je_fisc/shared/widgets/buttons/app_button.dart';
import 'package:je_fisc/shared/widgets/inputs/app_date_input.dart';
import 'package:je_fisc/shared/widgets/inputs/app_input.dart';
import 'package:je_fisc/shared/widgets/layouts/app_single_scroll_view.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../shared/widgets/app_status_view.dart';
import '../../../../../shared/widgets/overlays/app_toast.dart';

/// The bloc is provided by `WorkPage`, so this only reads it — which is what
/// lets a widget test pump it with a bloc of its own.
///
/// [AppStatusView] covers the screen's own load (the biometric check); once
/// that succeeds, `WorkList` handles loading, empty and error for the works
/// themselves, page by page.
class WorkCreateView extends StatefulWidget {
  const WorkCreateView({super.key, this.workId});

  /// The work to edit; null to add one.
  final int? workId;

  @override
  State<WorkCreateView> createState() => _WorkCreateViewState();
}

class _WorkCreateViewState extends State<WorkCreateView> {
  final _formKey = GlobalKey<FormState>();
  final _clientCtr = TextEditingController();
  final _addressCtr = TextEditingController();
  final _startDCtr = TextEditingController();
  final _endDCtr = TextEditingController();

  @override
  void dispose() {
    _clientCtr.dispose();
    _addressCtr.dispose();
    _startDCtr.dispose();
    _endDCtr.dispose();
    super.dispose();
  }

  /// Starts the form from the work being edited, once it has loaded.
  void _fill(WorkModel work) {
    _clientCtr.text = work.clientName;
    _addressCtr.text = work.address;
    _startDCtr.text = work.startDate.formattedDate;
    _endDCtr.text = work.endDate?.formattedDate ?? '';
  }

  void _save(WorkModel? editing) {
    if (!_formKey.isValid) return;
    context.read<WorkCreateBloc>().add(
      WorkCreateRequested(
        work: WorkModel(
          id: editing?.id ?? 0,
          clientName: _clientCtr.trimmed,
          address: _addressCtr.trimmed,
          startDate: _startDCtr.text.toDateTime()!,
          endDate: _endDCtr.text.toDateTime(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocSelector<WorkCreateBloc, WorkCreateState, bool>(
          selector: (state) => state.isEditing,
          builder: (context, isEditing) =>
              Text(isEditing ? 'Editar Obra' : 'Nova Obra'),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<WorkCreateBloc, WorkCreateState>(
          listenWhen: (previous, current) =>
              previous.errorMessage != current.errorMessage ||
              previous.successMessage != current.successMessage ||
              previous.createdWorkId != current.createdWorkId ||
              previous.isUpdated != current.isUpdated ||
              previous.work != current.work,
          listener: (context, state) {
            final error = state.errorMessage;
            if (error != null) AppToast.error(context, error);

            final success = state.successMessage;
            if (success != null) AppToast.success(context, success);

            if (state.createdWorkId != null) {
              appRouter.replace(AppRoutes.workDetailOf(state.createdWorkId!));
              return;
            }

            // `true` tells the detail screen to reload the work.
            if (state.isUpdated) {
              context.pop(true);
              return;
            }

            final work = state.work;
            if (work != null) _fill(work);
          },
          builder: (context, state) => AppStatusView(
            status: state.status,
            message: state.errorMessage,
            onRetry: () => context.read<WorkCreateBloc>().add(
              WorkCreateStarted(workId: widget.workId),
            ),
            builder: (context) {
              return AppSingleScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    spacing: AppConstants.space12,
                    children: [
                      AppInput(
                        label: "Nome do Cliente",
                        required: true,
                        controller: _clientCtr,
                      ),
                      AppInput(
                        label: "Morada",
                        required: true,
                        controller: _addressCtr,
                      ),
                      Row(
                        spacing: AppConstants.space12,
                        children: [
                          Expanded(
                            child: AppDateInput(
                              label: "Data de Início",
                              required: true,
                              controller: _startDCtr,
                            ),
                          ),
                          Expanded(
                            child: AppInput(
                              label: "Data de Fim",
                              controller: _endDCtr,
                            ),
                          ),
                        ],
                      ),
                      AppButton(
                        variant: AppButtonVariant.primary,
                        label: state.isEditing ? "Guardar" : "Criar Obra",
                        onPressed: () => _save(state.work),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
