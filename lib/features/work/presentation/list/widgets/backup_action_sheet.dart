import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:je_fisc/shared/widgets/lists/app_list_tile.dart';
import 'package:je_fisc/shared/widgets/overlays/app_bottom_modals.dart';
import 'package:je_fisc/shared/widgets/overlays/app_bottom_sheet_scaffold.dart';

/// What the Backup button can do.
enum BackupAction { export, import }

/// Asks whether to save a backup or import one. Pops the chosen
/// [BackupAction], or null when dismissed.
class BackupActionSheet extends StatelessWidget {
  const BackupActionSheet({super.key});

  static Future<BackupAction?> show() => AppBottomModals()
      .showAppBottomModal<BackupAction>(child: const BackupActionSheet());

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetScaffold(
      title: 'Cópia de segurança',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppListTile(
            leading: const Icon(Icons.download_outlined),
            title: 'Exportar cópia',
            subtitle: 'Guardar todos os dados num ficheiro',
            onTap: () => context.pop(BackupAction.export),
          ),
          AppListTile(
            leading: const Icon(Icons.upload_file_outlined),
            title: 'Importar cópia',
            subtitle: 'Adicionar os dados de uma cópia que ainda não existem',
            onTap: () => context.pop(BackupAction.import),
          ),
        ],
      ),
    );
  }
}
