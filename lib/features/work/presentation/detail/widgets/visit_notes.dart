import 'package:flutter/material.dart';
import 'package:je_fisc/core/constants/app_constants.dart';
import 'package:je_fisc/core/utils/extensions.dart';

/// A visit's notes under a small icon. [maxLines] clamps them with an
/// ellipsis — the card's preview; null shows every line — the detail sheet.
class VisitNotes extends StatelessWidget {
  const VisitNotes({super.key, required this.notes, this.maxLines});

  final String notes;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final color = context.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppConstants.space8,
      children: [
        Icon(Icons.notes_outlined, size: AppConstants.iconSmall, color: color),
        Expanded(
          child: Text(
            notes,
            maxLines: maxLines,
            overflow: maxLines == null ? null : TextOverflow.ellipsis,
            style: context.textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
