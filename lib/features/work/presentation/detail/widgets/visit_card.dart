import 'package:flutter/material.dart';
import 'package:je_fisc/core/constants/app_constants.dart';
import 'package:je_fisc/core/utils/extensions.dart';
import 'package:je_fisc/features/work/domain/models/visit_model.dart';
import 'package:je_fisc/features/work/presentation/detail/widgets/visit_categories.dart';
import 'package:je_fisc/features/work/presentation/detail/widgets/visit_detail_sheet.dart';
import 'package:je_fisc/features/work/presentation/detail/widgets/visit_picture.dart';
import 'package:je_fisc/shared/widgets/buttons/app_button.dart';
import 'package:je_fisc/shared/widgets/cards/app_card.dart';

/// One visit in the work's list: its first picture, the date, every
/// category, and a way into [VisitDetailSheet] for the rest of the pictures.
class VisitCard extends StatelessWidget {
  const VisitCard({super.key, required this.visit});

  final VisitModel visit;

  static const _pictureAspectRatio = 16 / 9;

  @override
  Widget build(BuildContext context) {
    final cover = visit.pictures.firstOrNull;
    final pictureCount = visit.pictures.length;

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => VisitDetailSheet.show(visit),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (cover != null)
            AspectRatio(
              aspectRatio: _pictureAspectRatio,
              child: VisitPicture(path: cover.picturePath),
            ),
          Padding(
            padding: AppConstants.padding16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppConstants.space8,
              children: [
                Row(
                  spacing: AppConstants.space8,
                  children: [
                    const Icon(
                      Icons.event_outlined,
                      size: AppConstants.iconSmall,
                    ),
                    Expanded(
                      child: Text(
                        visit.date.formattedDateTime,
                        style: context.textTheme.titleMedium,
                      ),
                    ),
                    if (pictureCount > 0) ...[
                      Icon(
                        Icons.photo_library_outlined,
                        size: AppConstants.iconSmall,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                      Text(
                        '$pictureCount',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
                VisitCategories(categories: visit.categories),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: AppButton(
                    variant: AppButtonVariant.primary,
                    type: AppButtonType.ghost,
                    size: AppButtonSize.small,
                    label: 'Ver detalhes',
                    onPressed: () => VisitDetailSheet.show(visit),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
