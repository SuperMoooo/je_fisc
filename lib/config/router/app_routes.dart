abstract final class AppRoutes {
  static const home = '/';
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';

  /// Routes reachable without a session. Everything else redirects to [login].
  static const publicRoutes = {login, register};

  // `moarch create feature` adds each feature's path above the next line —
  // keep it.
  // moarch:routes

  // Dynamic routes: the constant holds the pattern GoRouter matches on, the
  // `Of` helper builds the location you navigate to. Rename these to your own.
  static const featureDetail = '/detail/:id';

  static String featureDetailOf(String id) => '/detail/$id';
}
