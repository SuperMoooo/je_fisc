import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import './app_routes.dart';

/// Navigate without a BuildContext: `appRouter.go(...)`.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// The app's router. A plain top-level value rather than something resolved
/// from the locator: `MaterialApp.router` needs the same instance for the
/// life of the app, and rebuilding it would drop the navigation stack.
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.home,
  // Debug builds only: the route log is noise in release, and the locations
  // it prints can carry path parameters worth not logging.
  debugLogDiagnostics: kDebugMode,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('Home — replace me!')),
      ),
    ),

    // A screen with its own bloc points at its page, which creates the bloc —
    // so closing the route closes it. `moarch create feature` adds each
    // feature's route above the next line — keep it.
    // moarch:routes

    // Path parameter — build the location with AppRoutes.featureDetailOf(id).
    // GoRoute(
    //   path: AppRoutes.featureDetail,
    //   builder: (context, state) =>
    //       FeatureDetailPage(id: state.pathParameters['id']!),
    // ),
  ],
);
