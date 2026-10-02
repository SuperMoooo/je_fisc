import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_constants.dart';
import '../blocs/work_bloc.dart';
import '../blocs/work_event.dart';

/// The app bar's Backup action: saves a copy of the whole database where the
/// user picks. Shows a spinner, and ignores taps, while one is being written.
class WorkBackupButton extends StatelessWidget {
  const WorkBackupButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isBackingUp = context.select<WorkBloc, bool>(
      (bloc) => bloc.state.isBackingUp,
    );
    return Padding(
      padding: const EdgeInsets.only(right: AppConstants.space8),
      child: TextButton.icon(
        onPressed: isBackingUp
            ? null
            : () => context.read<WorkBloc>().add(const WorkBackupRequested()),
        icon: isBackingUp
            ? const SizedBox.square(
                dimension: AppConstants.iconSmall,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.download_outlined),
        label: const Text('Backup'),
      ),
    );
  }
}
