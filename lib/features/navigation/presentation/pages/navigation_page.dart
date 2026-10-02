import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/injector.dart';
import '../blocs/navigation_bloc.dart';
import '../blocs/navigation_event.dart';
import '../views/navigation_view.dart';

/// The `StatefulShellRoute`'s builder: owns the lock's bloc for as long as
/// the tabs are on screen, which is the life of the app.
class NavigationPage extends StatelessWidget {
  const NavigationPage({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<NavigationBloc>()..add(const NavigationStarted()),
      child: NavigationView(shell: shell),
    );
  }
}
