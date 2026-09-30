import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:je_fisc/features/work/presentation/detail/blocs/work_detail_bloc.dart';
import 'package:je_fisc/features/work/presentation/detail/blocs/work_detail_event.dart';

import '../../../../../config/di/injector.dart';
import '../views/work_detail_view.dart';

/// Creates the bloc and owns it: leaving the route closes it.
///
/// Put this in your `GoRoute` builder. If the screen is pushed from another
/// that already has the bloc, use `BlocProvider.value` instead — creating a
/// second one would give the two screens separate states.
class WorkDetailPage extends StatelessWidget {
  const WorkDetailPage({super.key, required this.workId});

  final int workId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // ..add(...) here rather than in the constructor: a bloc that emits
      // during its own construction has no listener yet.
      create: (_) =>
          getIt<WorkDetailBloc>()..add(WorkDetailStarted(workId: workId)),
      child: const WorkDetailView(),
    );
  }
}
