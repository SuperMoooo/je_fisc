import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/injector.dart';
import '../blocs/calendar_bloc.dart';
import '../blocs/calendar_event.dart';
import '../views/calendar_view.dart';

/// Owns the bloc: leaving the route closes it.
class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CalendarBloc>()..add(const CalendarStarted()),
      child: const CalendarView(),
    );
  }
}
