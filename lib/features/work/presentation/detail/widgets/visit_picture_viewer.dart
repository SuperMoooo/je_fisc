import 'package:flutter/material.dart';
import 'package:je_fisc/features/work/presentation/detail/widgets/visit_picture.dart';

/// One picture full screen, pinch to zoom.
class VisitPictureViewer extends StatelessWidget {
  const VisitPictureViewer({super.key, required this.path});

  final String path;

  /// How far in a pinch may zoom.
  static const _maxScale = 5.0;

  static Future<void> show(BuildContext context, String path) => showDialog(
    context: context,
    builder: (_) => VisitPictureViewer(path: path),
  );

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(),
        body: InteractiveViewer(
          maxScale: _maxScale,
          child: Center(
            child: VisitPicture(path: path, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
