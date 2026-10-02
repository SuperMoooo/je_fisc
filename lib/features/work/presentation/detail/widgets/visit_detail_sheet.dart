import 'package:flutter/material.dart';
import 'package:je_fisc/core/constants/app_constants.dart';
import 'package:je_fisc/core/utils/extensions.dart';
import 'package:je_fisc/features/work/domain/models/visit_model.dart';
import 'package:je_fisc/features/work/presentation/detail/widgets/visit_categories.dart';
import 'package:je_fisc/features/work/presentation/detail/widgets/visit_notes.dart';
import 'package:je_fisc/features/work/presentation/detail/widgets/visit_picture.dart';
import 'package:je_fisc/features/work/presentation/detail/widgets/visit_picture_viewer.dart';
import 'package:je_fisc/shared/widgets/empty_view.dart';
import 'package:je_fisc/shared/widgets/overlays/app_bottom_modals.dart';
import 'package:je_fisc/shared/widgets/overlays/app_bottom_sheet_scaffold.dart';

/// Everything about one visit: its date, every category, its notes and every
/// picture.
///
/// Draws the [VisitModel] it is handed and nothing else, so it needs no bloc.
class VisitDetailSheet extends StatelessWidget {
  const VisitDetailSheet({super.key, required this.visit});

  final VisitModel visit;

  /// The share of the screen the sheet may grow to before it scrolls.
  static const _maxHeightFactor = 0.8;
  static const _columns = 2;

  static Future<void> show(VisitModel visit) => AppBottomModals()
      .showAppBottomModal(child: VisitDetailSheet(visit: visit));

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetScaffold(
      title:
          'Visita de ${visit.date.formattedDate} às ${visit.date.formattedTime}',
      showClose: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * _maxHeightFactor,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppConstants.space16,
            children: [
              VisitCategories(categories: visit.categories),
              if (visit.notes case final notes?) VisitNotes(notes: notes),
              if (visit.pictures.isEmpty)
                const EmptyView(
                  title: 'Sem fotografias',
                  message: 'Esta visita não tem fotografias.',
                  icon: Icons.photo_library_outlined,
                )
              else
                GridView.count(
                  crossAxisCount: _columns,
                  mainAxisSpacing: AppConstants.space8,
                  crossAxisSpacing: AppConstants.space8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final picture in visit.pictures)
                      GestureDetector(
                        onTap: () => VisitPictureViewer.show(
                          context,
                          picture.picturePath,
                        ),
                        child: ClipRRect(
                          borderRadius: AppConstants.borderRadius12,
                          child: VisitPicture(path: picture.picturePath),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
