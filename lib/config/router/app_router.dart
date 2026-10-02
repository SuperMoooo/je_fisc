import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:je_fisc/core/utils/extensions.dart';
import 'package:je_fisc/features/work/presentation/create/pages/work_create_page.dart';
import 'package:je_fisc/features/work/presentation/detail/pages/work_detail_page.dart';
import 'package:je_fisc/features/work/presentation/visit_create/pages/visit_create_page.dart';

import '../../features/work/presentation/list/pages/work_page.dart';
import './app_routes.dart';
import '../../features/category/presentation/pages/category_page.dart';
import '../../features/calendar/presentation/pages/calendar_page.dart';
import '../../features/navigation/presentation/pages/navigation_page.dart';

/// Navigate without a BuildContext: `appRouter.go(...)`.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// The app's router. A plain top-level value rather than something resolved
/// from the locator: `MaterialApp.router` needs the same instance for the
/// life of the app, and rebuilding it would drop the navigation stack.
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.work,
  // Debug builds only: the route log is noise in release, and the locations
  // it prints can carry path parameters worth not logging.
  debugLogDiagnostics: kDebugMode,
  routes: [
    // The tabs. NavigationPage holds the biometric lock and the bottom bar;
    // the branches are in the order of its destinations.
    StatefulShellRoute(
      builder: (context, state, shell) => NavigationPage(shell: shell),
      // Only the open tab is built, so switching to one rebuilds it and its
      // bloc loads fresh — a visit added from Obras is on the calendar the
      // moment it is opened. The router still remembers each tab's location.
      navigatorContainerBuilder: (context, shell, children) =>
          children[shell.currentIndex],
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.work,
              builder: (context, state) => const WorkPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.calendar,
              builder: (context, state) => const CalendarPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.category,
              builder: (context, state) => const CategoryPage(),
            ),
          ],
        ),
      ],
    ),

    // Over the tabs, on the root navigator. `create` before `:workId`, which
    // would otherwise take it as an id.
    GoRoute(
      path: AppRoutes.createWork,
      builder: (context, state) => const WorkCreatePage(),
    ),
    GoRoute(
      path: AppRoutes.workDetail,
      builder: (context, state) => WorkDetailPage(
        workId: state.pathParameters["workId"]?.toIntOrNull ?? 0,
      ),
      routes: [
        GoRoute(
          path: AppRoutes.createVisitSegment,
          builder: (context, state) => VisitCreatePage(
            workId: state.pathParameters["workId"]?.toIntOrNull ?? 0,
          ),
        ),
        GoRoute(
          path: AppRoutes.editVisitSegment,
          builder: (context, state) => VisitCreatePage(
            workId: state.pathParameters["workId"]?.toIntOrNull ?? 0,
            visitId: state.pathParameters["visitId"]?.toIntOrNull,
          ),
        ),
        GoRoute(
          path: AppRoutes.editWorkSegment,
          builder: (context, state) => WorkCreatePage(
            workId: state.pathParameters["workId"]?.toIntOrNull,
          ),
        ),
      ],
    ),
    // moarch:routes

    // Path parameter — build the location with AppRoutes.featureDetailOf(id).
    // GoRoute(
    //   path: AppRoutes.featureDetail,
    //   builder: (context, state) =>
    //       FeatureDetailPage(id: state.pathParameters['id']!),
    // ),
  ],
);
