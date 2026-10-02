import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:je_fisc/config/router/app_router.dart';
import 'package:je_fisc/config/router/app_routes.dart';
import 'package:je_fisc/features/work/domain/models/work_model.dart';
import 'package:je_fisc/features/work/presentation/list/widgets/work_card.dart';
import 'package:je_fisc/shared/widgets/inputs/app_input.dart';
import 'package:je_fisc/shared/widgets/inputs/app_input_config.dart';
import 'package:je_fisc/shared/widgets/lists/app_paged_list.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../shared/widgets/app_status_view.dart';
import '../../../../../shared/widgets/overlays/app_toast.dart';
import '../blocs/work_bloc.dart';
import '../blocs/work_event.dart';
import '../blocs/work_state.dart';
import '../widgets/work_list_skeleton.dart';

/// The bloc is provided by `WorkPage`, so this only reads it — which is what
/// lets a widget test pump it with a bloc of its own.
///
/// [AppStatusView] covers the screen's first load (the first page of works);
/// after it, `WorkList` draws the pages that follow, with their own loading
/// and retry row at the end of the list.
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
            emptyTitle: 'Nenhuma obra encontrada',
            emptyMessage: 'As obras que criar aparecem aqui.',
            emptyIcon: Icons.construction_outlined,
            onRetry: () => context.read<WorkBloc>().add(const WorkStarted()),
            skeleton: (context) => const WorkListSkeleton(),
            builder: (context) {
              final bloc = context.read<WorkBloc>();
              return Padding(
                padding: AppConstants.paddingPage,
                child: Column(
                  crossAxisAlignment: .end,
                  spacing: AppConstants.space12,
                  children: [
                    AppInput(
                      label: 'Pesquisar obras',
                      hint: 'Pesquisar por cliente ou morada',
                      labelMode: AppInputLabelMode.placeholder,
                      initialValue: state.query,
                      prefixIcon: const Icon(Icons.search),
                      textInputAction: TextInputAction.search,
                      onChanged: (query) => context.read<WorkBloc>().add(
                        WorkSearchChanged(query),
                      ),
                    ),

                    Expanded(
                      child: AppPagedList<WorkModel>(
                        items: state.works.items,
                        hasMore: state.works.hasMore,
                        isLoadingMore: state.works.isLoadingMore,
                        error: state.works.error,
                        onLoadMore: () => bloc.add(const WorkMoreRequested()),
                        onRefresh: () {
                          bloc.add(const WorkRefreshed());
                          return bloc.stream.first;
                        },
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppConstants.space8),
                        itemBuilder: (context, work) => WorkCard(
                          work: work,
                          onTap: () =>
                              appRouter.push(AppRoutes.workDetailOf(work.id)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
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
