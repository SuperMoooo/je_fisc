import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:je_fisc/config/router/app_router.dart';
import 'package:je_fisc/config/router/app_routes.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../shared/widgets/app_status_view.dart';
import '../../../../../shared/widgets/overlays/app_toast.dart';
import '../blocs/work_bloc.dart';
import '../blocs/work_event.dart';
import '../blocs/work_state.dart';
import '../widgets/work_list.dart';
import '../widgets/work_list_skeleton.dart';
import '../widgets/work_search_field.dart';

/// The bloc is provided by `WorkPage`, so this only reads it — which is what
/// lets a widget test pump it with a bloc of its own.
///
/// [AppStatusView] covers the screen's own load (the biometric check); once
/// that succeeds, `WorkList` handles loading, empty and error for the works
/// themselves, page by page.
class WorkView extends StatelessWidget {
  const WorkView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<WorkBloc, WorkState>(
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
            onRetry: () => context.read<WorkBloc>().add(const WorkStarted()),
            skeleton: (context) => const WorkListSkeleton(),
            builder: (context) => Padding(
              padding: AppConstants.paddingPage,
              child: Column(
                crossAxisAlignment: .end,
                spacing: AppConstants.space12,
                children: [
                  WorkSearchField(initialQuery: state.query),

                  Expanded(
                    // Keyed by the query: a new search starts a new list from
                    // page 1 instead of appending to the old results.
                    child: WorkList(
                      key: ValueKey(state.query),
                      query: state.query,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_circle_outline),
        onPressed: () => appRouter.push(AppRoutes.createWork),
        label: const Text("Nova Obra"),
      ),
    );
  }
}
