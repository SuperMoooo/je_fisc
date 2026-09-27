import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/app_status_view.dart';
import '../../../../shared/widgets/overlays/app_toast.dart';
import '../blocs/work_bloc.dart';
import '../blocs/work_event.dart';
import '../blocs/work_state.dart';

/// The bloc is provided by `WorkPage`, so this only reads it — which is what
/// lets a widget test pump it with a bloc of its own.
class WorkView extends StatelessWidget {
  const WorkView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Obras')),
      body: BlocConsumer<WorkBloc, WorkState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage ||
            previous.successMessage != current.successMessage,
        listener: (context, state) {
          final error = state.errorMessage;
          if (error != null) AppToast.error(context, error);

          final success = state.successMessage;
          if (success != null) AppToast.success(context, success);
          // TODO: what else should happen once — a pop, a dialog, a push.
        },
        // AppStatusView owns the three shells every screen has — skeleton,
        // failure, empty — so all this has to name is the body.
        builder: (context, state) => AppStatusView(
          status: state.status,
          message: state.errorMessage,
          onRetry: () => context.read<WorkBloc>().add(const WorkStarted()),
          // TODO: once the state has a list, say when it counts as empty:
          // `isEmpty: state.items.isEmpty,`.
          skeleton: (context) => _body(context, WorkState.placeholder),
          builder: (context) => _body(context, state),
        ),
      ),
    );
  }

  // Handed the whole state whatever the status is, so drawing over data
  // already loaded needs nothing here.
  //
  // TODO: build the screen from `state`. It is also what the skeleton is
  // traced from, so every field you draw needs a fake value in
  // `WorkState.placeholder` — Skeletonizer shimmers the tree it is handed,
  // and a field left empty shimmers as a blank line. `BoneMock` (skeletonizer)
  // hands out fake strings, names and dates.
  Widget _body(BuildContext context, WorkState state) {
    return const SizedBox.shrink();
  }
}
