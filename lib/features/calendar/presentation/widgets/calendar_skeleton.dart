import 'package:flutter/material.dart';
import 'package:je_fisc/core/constants/app_constants.dart';
import 'package:je_fisc/shared/widgets/calendar/app_calendar.dart';

import '../blocs/calendar_state.dart';
import 'calendar_day_visits.dart';

/// The Calendar screen while its first load runs, drawn from
/// [CalendarState.placeholder] for the view's Skeletonizer to shimmer.
class CalendarSkeleton extends StatelessWidget {
  const CalendarSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final state = CalendarState.placeholder;
    return ListView(
      padding: AppConstants.paddingPage,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const AppCalendar(),
        const SizedBox(height: AppConstants.space16),
        CalendarDayVisits(day: state.selectedDay!, visits: state.visits),
      ],
    );
  }
}
