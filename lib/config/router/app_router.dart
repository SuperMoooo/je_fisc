import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:je_fisc/core/utils/extensions.dart';
import 'package:je_fisc/features/work/presentation/create/pages/work_create_page.dart';
import 'package:je_fisc/features/work/presentation/detail/pages/work_detail_page.dart';

import '../../features/work/presentation/list/pages/work_page.dart';
import './app_routes.dart';

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
    GoRoute(
      path: AppRoutes.work,
      builder: (context, state) => const WorkPage(),
      routes: [
        GoRoute(
          path: AppRoutes.createWorkSegment,
          builder: (context, state) => const WorkCreatePage(),
        ),
        GoRoute(
          path: AppRoutes.workDetailsSegment,
          builder: (context, state) => WorkDetailPage(
            workId: state.pathParameters["workId"]?.toIntOrNull ?? 0,
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
