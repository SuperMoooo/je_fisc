import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  const WorkCreateView({super.key});

  @override
  State<WorkCreateView> createState() => _WorkCreateViewState();
}

class _WorkCreateViewState extends State<WorkCreateView> {
  final _formKey = GlobalKey<FormState>();
  final _clientCtr = TextEditingController();
  final _addressCtr = TextEditingController();
  final _startDCtr = TextEditingController();
  final _endDCtr = TextEditingController();

  void _create() {
    if (!_formKey.isValid) return;
    context.read<WorkCreateBloc>().add(
      WorkCreateRequested(
        work: WorkModel(
          id: 0,
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
      body: SafeArea(
        child: BlocConsumer<WorkCreateBloc, WorkCreateState>(
          listenWhen: (previous, current) =>
              previous.errorMessage != current.errorMessage ||
              previous.successMessage != current.successMessage,
          listener: (context, state) {
            final error = state.errorMessage;
            if (error != null) AppToast.error(context, error);

            final success = state.successMessage;
            if (success != null) AppToast.success(context, success);

            if (state.createdWorkId != null) {
              appRouter.replace(AppRoutes.workDetailOf(state.createdWorkId!));
              return;
            }
          },
          builder: (context, state) => AppStatusView(
            status: state.status,
            message: state.errorMessage,
            onRetry: () =>
                context.read<WorkCreateBloc>().add(const WorkCreateStarted()),
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
                        label: "Criar Obra",
                        onPressed: _create,
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
