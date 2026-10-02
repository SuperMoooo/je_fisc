import 'package:flutter/material.dart';
import 'package:je_fisc/core/utils/extensions.dart';
import 'package:je_fisc/features/calendar/domain/models/calendar_visit_model.dart';
import 'package:je_fisc/shared/widgets/lists/app_card_tile.dart';

/// One visit under the calendar: when, whose work it was, and where.
class CalendarVisitTile extends StatelessWidget {
  const CalendarVisitTile({super.key, required this.visit, this.onTap});

  final CalendarVisitModel visit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCardTile(
      leading: const Icon(Icons.construction_outlined),
      title: visit.clientName,
      subtitle: '${visit.date.formattedTime} · ${visit.address}',
      showChevron: true,
      onTap: onTap,
    );
  }
}
