import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:je_fisc/shared/widgets/navigation/app_bottom_nav.dart';

import '../../../../shared/widgets/app_status_view.dart';
import '../blocs/navigation_bloc.dart';
import '../blocs/navigation_event.dart';
import '../blocs/navigation_state.dart';

/// The app's frame: the biometric lock first, then the current tab over the
/// bottom bar.
///
/// The tab is not built until the lock opens, so no screen behind it loads
/// its data before the user is through.
class NavigationView extends StatelessWidget {
  const NavigationView({super.key, required this.shell});

  final StatefulNavigationShell shell;

  /// In branch order — the router's `StatefulShellRoute` lists the branches
  /// in this same order.
  static const _destinations = [
    AppNavDestination(
      icon: Icons.construction_outlined,
      selectedIcon: Icons.construction,
      label: 'Obras',
    ),
    AppNavDestination(
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      label: 'Calendário',
    ),
    AppNavDestination(
      icon: Icons.label_outline,
      selectedIcon: Icons.label,
      label: 'Categorias',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) => Scaffold(
        body: AppStatusView(
          status: state.status,
          message: state.errorMessage,
          errorTitle: 'Autenticação necessária',
          onRetry: () =>
              context.read<NavigationBloc>().add(const NavigationStarted()),
          builder: (context) => shell,
        ),
        bottomNavigationBar: state.status.isSuccess
            ? AppBottomNav(
                index: shell.currentIndex,
                destinations: _destinations,
                // Tapping the tab already open goes back to its first screen.
                onDestinationSelected: (index) => shell.goBranch(
                  index,
                  initialLocation: index == shell.currentIndex,
                ),
              )
            : null,
      ),
    );
  }
}
