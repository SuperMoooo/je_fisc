abstract final class AppRoutes {
  static const home = '/';
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';

  /// Routes reachable without a session. Everything else redirects to [login].
  static const publicRoutes = {login, register};

  // `moarch create feature` adds each feature's path above the next line —
  // keep it.
  // Full locations — navigate with these.
  //
  // The tabs, each a branch of the StatefulShellRoute in app_router.dart.
  static const work = '/work';
  static const calendar = '/calendar';
  static const category = '/category';

  // Full-screen routes over the tabs. Top level rather than nested under
  // [work], so they cover the bottom bar and can be pushed from any tab
  // without switching to Obras underneath.
  static const createWork = '/work/create';
  static const workDetail = '/work/:workId';
  static String workDetailOf(int id) => '/work/$id';
  static String createVisitOf(int workId) =>
      '${workDetailOf(workId)}/$createVisitSegment';
  static String editWorkOf(int workId) =>
      '${workDetailOf(workId)}/$editWorkSegment';
  static String editVisitOf(int workId, int visitId) =>
      '${workDetailOf(workId)}/visits/$visitId/edit';

  // Child segment of [workDetail] — GoRouter joins a nested route's path
  // onto its parent's.
  static const createVisitSegment = 'visits/create';
  static const editWorkSegment = 'edit';
  static const editVisitSegment = 'visits/:visitId/edit';
  // moarch:routes

  // Dynamic routes: the constant holds the pattern GoRouter matches on, the
  // `Of` helper builds the location you navigate to. Rename these to your own.
  static const featureDetail = '/detail/:id';

  static String featureDetailOf(String id) => '/detail/$id';
}
