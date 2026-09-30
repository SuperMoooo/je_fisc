import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:je_fisc/features/work/presentation/create/blocs/work_create_bloc.dart';
import 'package:je_fisc/features/work/presentation/create/blocs/work_create_event.dart';
import 'package:je_fisc/features/work/presentation/create/blocs/work_create_state.dart';
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
                  child: const Column(
                    spacing: AppConstants.space12,
                    children: [],
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
