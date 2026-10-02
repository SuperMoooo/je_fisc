import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:je_fisc/config/router/app_router.dart';
import 'package:je_fisc/config/router/app_routes.dart';
import 'package:je_fisc/core/constants/app_constants.dart';
import 'package:je_fisc/features/calendar/domain/models/calendar_visit_model.dart';
import 'package:je_fisc/shared/widgets/calendar/app_calendar.dart';

import '../../../../shared/widgets/app_status_view.dart';
import '../../../../shared/widgets/overlays/app_toast.dart';
import '../blocs/calendar_bloc.dart';
import '../blocs/calendar_event.dart';
import '../blocs/calendar_state.dart';
import '../widgets/calendar_day_visits.dart';
import '../widgets/calendar_skeleton.dart';

/// The month with a dot under every day that had a visit, and the tapped
/// day's visits below it.
class CalendarView extends StatelessWidget {
  const CalendarView({super.key});

  /// Opens the visit's work, and reloads on the way back — a visit may have
  /// been added there.
  Future<void> _openWork(BuildContext context, CalendarVisitModel visit) async {
    final bloc = context.read<CalendarBloc>();
    await appRouter.push(AppRoutes.workDetailOf(visit.workId));
    bloc.add(const CalendarRefreshed());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendário')),
      body: BlocConsumer<CalendarBloc, CalendarState>(
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
              context.read<CalendarBloc>().add(const CalendarStarted()),
          skeleton: (context) => const CalendarSkeleton(),
          builder: (context) {
            final bloc = context.read<CalendarBloc>();
            final day = state.selectedDay;
            return ListView(
              padding: AppConstants.paddingPage,
              children: [
                AppCalendar(
                  locale: 'pt_PT',
                  selected: day,
                  focusedMonth: state.first,
                  events: state.visitsPerDay,
                  onSelected: (day) => bloc.add(CalendarDaySelected(day)),
                  onMonthChanged: (first, last) =>
                      bloc.add(CalendarRangeChanged(first: first, last: last)),
                ),
                const SizedBox(height: AppConstants.space16),
                if (day != null)
                  CalendarDayVisits(
                    day: day,
                    visits: state.selectedVisits,
                    onVisitTap: (visit) => _openWork(context, visit),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
