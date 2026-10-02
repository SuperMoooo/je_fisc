import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_constants.dart';
import '../blocs/work_bloc.dart';
import '../blocs/work_event.dart';
import 'backup_action_sheet.dart';

/// The app bar's Backup action: asks whether to save a copy of the whole
/// database where the user picks, or to import one. Shows a spinner, and
/// ignores taps, while either is running.
class WorkBackupButton extends StatelessWidget {
  const WorkBackupButton({super.key});

  Future<void> _choose(BuildContext context) async {
    final bloc = context.read<WorkBloc>();
    final action = await BackupActionSheet.show();
    if (action == null || bloc.isClosed) return;
    bloc.add(switch (action) {
      BackupAction.export => const WorkBackupRequested(),
      BackupAction.import => const WorkBackupImportRequested(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final isBackingUp = context.select<WorkBloc, bool>(
      (bloc) => bloc.state.isBackingUp,
    );
    return Padding(
      padding: const EdgeInsets.only(right: AppConstants.space8),
      child: TextButton.icon(
        onPressed: isBackingUp ? null : () => _choose(context),
        icon: isBackingUp
            ? const SizedBox.square(
                dimension: AppConstants.iconSmall,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.backup_outlined),
        label: const Text('Backup'),
      ),
    );
  }
}
