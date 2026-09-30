import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:je_fisc/features/work/presentation/detail/blocs/work_detail_bloc.dart';
import 'package:je_fisc/features/work/presentation/detail/blocs/work_detail_event.dart';
import 'package:je_fisc/features/work/presentation/detail/blocs/work_detail_state.dart';
import 'package:je_fisc/features/work/presentation/detail/widgets/work_detail_skeleton.dart';
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
class WorkDetailView extends StatelessWidget {
  const WorkDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<WorkDetailBloc, WorkDetailState>(
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
            onRetry: () => context.read<WorkDetailBloc>().add(
              WorkDetailStarted(workId: state.work?.id ?? 0),
            ),
            skeleton: (context) => const WorkDetailSkeleton(),
            builder: (context) {
              return const AppSingleScrollView(
                child: Column(spacing: AppConstants.space12),
              );
            },
          ),
        ),
      ),
    );
  }
}
