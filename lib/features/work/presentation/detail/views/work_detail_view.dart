import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:je_fisc/config/router/app_router.dart';
import 'package:je_fisc/config/router/app_routes.dart';
import 'package:je_fisc/core/utils/extensions.dart';
import 'package:je_fisc/features/work/presentation/detail/blocs/work_detail_bloc.dart';
import 'package:je_fisc/features/work/presentation/detail/blocs/work_detail_event.dart';
import 'package:je_fisc/features/work/presentation/detail/blocs/work_detail_state.dart';
import 'package:je_fisc/features/work/presentation/detail/widgets/visit_card.dart';
import 'package:je_fisc/features/work/presentation/detail/widgets/work_detail_skeleton.dart';
import 'package:je_fisc/shared/widgets/buttons/app_button.dart';
import 'package:je_fisc/shared/widgets/empty_view.dart';
import 'package:je_fisc/shared/widgets/text/app_heading.dart';
import 'package:je_fisc/shared/widgets/layouts/app_single_scroll_view.dart';
import 'package:je_fisc/shared/widgets/text/app_rich_text.dart';

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
    final textTheme = context.textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text("Detalhes da Obra")),
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
              final work = state.work;
              final visits = state.visits;
              return AppSingleScrollView(
                child: Column(
                  crossAxisAlignment: .start,
                  spacing: AppConstants.space12,
                  children: [
                    Text(
                      work?.clientName ?? "N/A",
                      style: textTheme.titleLarge,
                    ),
                    Row(
                      spacing: AppConstants.space4,
                      mainAxisSize: .min,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: AppConstants.iconMedium - 4,
                        ),
                        Text(
                          work?.address ?? "N/A",
                          style: textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    Divider(
                      height: 0.5,
                      color: AppConstants.outline.withValues(alpha: 0.05),
                    ),
                    Row(
                      spacing: AppConstants.space12,
                      mainAxisAlignment: .spaceBetween,
                      children: [
                        Expanded(
                          child: AppRichText(
                            spans: [
                              const AppSpan("Inicio: "),
                              AppSpan(work?.startDate.formattedDate),
                            ],
                          ),
                        ),
                        Expanded(
                          child: AppRichText(
                            spans: [
                              const AppSpan("Fim Estimado: "),
                              AppSpan(
                                work?.endDate?.formattedDate ?? "??/??/????",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.space16),
                    AppButton(
                      variant: AppButtonVariant.primary,
                      label: "Nova Visita",
                      onPressed: work == null
                          ? null
                          : () async {
                              final created = await appRouter.push<bool>(
                                AppRoutes.createVisitOf(work.id),
                              );
                              // Status is already success, so this reloads
                              // in place rather than back to the skeleton.
                              if (created == true && context.mounted) {
                                context.read<WorkDetailBloc>().add(
                                  WorkDetailStarted(workId: work.id),
                                );
                              }
                            },
                    ),
                    const SizedBox(height: AppConstants.space8),
                    const AppHeading(title: "Visitas"),
                    if (visits.isEmpty)
                      const EmptyView(
                        title: "Sem visitas",
                        message: "Esta obra ainda não tem visitas.",
                        icon: Icons.event_busy_outlined,
                      )
                    else
                      for (final visit in visits) VisitCard(visit: visit),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
