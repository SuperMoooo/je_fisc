import 'dart:io';

import 'package:flutter/material.dart';
import 'package:je_fisc/core/constants/app_constants.dart';
import 'package:je_fisc/core/utils/extensions.dart';

/// A visit picture from local storage, cropped to fill the space it is given.
///
/// A file that is missing — deleted from outside the app, or the empty path
/// the skeleton's placeholder carries — draws an icon instead of breaking.
class VisitPicture extends StatelessWidget {
  const VisitPicture({super.key, required this.path, this.fit = BoxFit.cover});

  final String path;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(path),
      fit: fit,
      errorBuilder: (context, error, stackTrace) => ColoredBox(
        color: context.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.08,
        ),
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: AppConstants.iconLarge,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
