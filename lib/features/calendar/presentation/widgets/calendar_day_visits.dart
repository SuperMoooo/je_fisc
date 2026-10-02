import 'package:flutter/material.dart';
import 'package:je_fisc/core/constants/app_constants.dart';
import 'package:je_fisc/core/utils/extensions.dart';
import 'package:je_fisc/features/calendar/domain/models/calendar_visit_model.dart';
import 'package:je_fisc/features/calendar/presentation/widgets/calendar_visit_tile.dart';
import 'package:je_fisc/shared/widgets/text/app_heading.dart';

/// The visits of one day, listed under the calendar.
class CalendarDayVisits extends StatelessWidget {
  const CalendarDayVisits({
    super.key,
    required this.day,
    required this.visits,
    this.onVisitTap,
  });

  final DateTime day;
  final List<CalendarVisitModel> visits;
  final ValueChanged<CalendarVisitModel>? onVisitTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppConstants.space8,
      children: [
        AppHeading(
          title: 'Visitas a ${day.formattedDate}',
          size: AppHeadingSize.small,
        ),
        if (visits.isEmpty)
          Text(
            'Sem visitas neste dia.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          )
        else
          for (final visit in visits)
            CalendarVisitTile(
              visit: visit,
              onTap: onVisitTap == null ? null : () => onVisitTap!(visit),
            ),
      ],
    );
  }
}
