import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:je_fisc/shared/widgets/lists/app_list_tile.dart';
import 'package:je_fisc/shared/widgets/overlays/app_bottom_modals.dart';
import 'package:je_fisc/shared/widgets/overlays/app_bottom_sheet_scaffold.dart';

/// Asks where a picture comes from. Pops the chosen [ImageSource], or null
/// when dismissed.
class PictureSourceSheet extends StatelessWidget {
  const PictureSourceSheet({super.key});

  static Future<ImageSource?> show() => AppBottomModals()
      .showAppBottomModal<ImageSource>(child: const PictureSourceSheet());

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetScaffold(
      title: 'Adicionar fotografia',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: 'Tirar fotografia',
            onTap: () => context.pop(ImageSource.camera),
          ),
          AppListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: 'Escolher da galeria',
            onTap: () => context.pop(ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}
