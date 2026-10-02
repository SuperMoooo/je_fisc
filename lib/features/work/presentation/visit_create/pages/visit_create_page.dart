import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:je_fisc/core/services/media_service.dart';
import 'package:je_fisc/features/work/presentation/visit_create/blocs/visit_create_bloc.dart';
import 'package:je_fisc/features/work/presentation/visit_create/blocs/visit_create_event.dart';

import '../../../../../config/di/injector.dart';
import '../views/visit_create_view.dart';

/// Creates the bloc and owns it: leaving the route closes it.
///
/// Pops `true` once the visit is saved, so the work's detail screen knows to
/// reload its visits — neither screen ever needs the other's bloc.
///
/// The picker is resolved here too, so the view stays off the locator and a
/// widget test can hand it a fake one.
class VisitCreatePage extends StatelessWidget {
  const VisitCreatePage({super.key, required this.workId, this.visitId});

  final int workId;

  /// The visit to edit; null to add one.
  final int? visitId;

  /// JPEG quality the pictures are saved at — plenty to read a crack by,
  /// at a fraction of the camera's file size.
  static const _imageQuality = 80;

  static Future<List<String>> _pickPictures(ImageSource source) async {
    final media = getIt<MediaService>();
    final files = switch (source) {
      ImageSource.camera => [
        ?await media.pickImage(source: source, imageQuality: _imageQuality),
      ],
      ImageSource.gallery =>
        await media.pickMultiImage(imageQuality: _imageQuality) ?? const [],
    };
    return [for (final file in files) file.path];
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // ..add(...) here rather than in the constructor: a bloc that emits
      // during its own construction has no listener yet.
      create: (_) =>
          getIt<VisitCreateBloc>()
            ..add(VisitCreateStarted(workId: workId, visitId: visitId)),
      child: VisitCreateView(
        workId: workId,
        visitId: visitId,
        pickPictures: _pickPictures,
      ),
    );
  }
}
