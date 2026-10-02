import '../../features/work/domain/repositories/work_repository.dart';
import '../../features/work/presentation/create/blocs/work_create_bloc.dart';
import '../../features/work/presentation/detail/blocs/work_detail_bloc.dart';
import '../../features/work/presentation/list/blocs/work_bloc.dart';
import '../../features/work/presentation/visit_create/blocs/visit_create_bloc.dart';
import 'injector.dart';
import '../../features/category/domain/repositories/category_repository.dart';
import '../../features/category/presentation/blocs/category_bloc.dart';
import '../../features/calendar/domain/repositories/calendar_repository.dart';
import '../../features/calendar/presentation/blocs/calendar_bloc.dart';
import '../../core/security/biometric_service.dart';
import '../../features/navigation/presentation/blocs/navigation_bloc.dart';

/// The state holders.
///
/// A feature bloc is a **factory**: each screen's `BlocProvider` creates its
/// own and closing the route closes it. Only the session-wide ones — auth,
/// the locale — are singletons, because the router's redirect and every
/// screen have to be reading the same instance.
void registerBlocs() {
  // ── Work ────────────────────────────────────────────────────
  // A factory, not a singleton: the screen's BlocProvider creates it and
  // closing the route closes it.
  getIt.registerFactory<WorkBloc>(() => WorkBloc(getIt<WorkRepository>()));

  // ── WorkDetails ─────────────────────────────────────────────
  // A factory, not a singleton: the screen's BlocProvider creates it and
  // closing the route closes it.
  getIt.registerFactory<WorkDetailBloc>(
    () => WorkDetailBloc(getIt<WorkRepository>()),
  );

  // ── WorkCreate ──────────────────────────────────────────────
  // A factory, not a singleton: the screen's BlocProvider creates it and
  // closing the route closes it.
  getIt.registerFactory<WorkCreateBloc>(
    () => WorkCreateBloc(getIt<WorkRepository>()),
  );

  // ── VisitCreate ─────────────────────────────────────────────
  // A factory, not a singleton: the screen's BlocProvider creates it and
  // closing the route closes it.
  getIt.registerFactory<VisitCreateBloc>(
    () => VisitCreateBloc(getIt<WorkRepository>(), getIt<CategoryRepository>()),
  );

  // ── Category ────────────────────────────────────────────────
  // A factory, not a singleton: the screen's BlocProvider creates it and
  // closing the route closes it.
  getIt.registerFactory<CategoryBloc>(
    () => CategoryBloc(getIt<CategoryRepository>()),
  );

  // ── Calendar ────────────────────────────────────────────────
  // A factory, not a singleton: the screen's BlocProvider creates it and
  // closing the route closes it.
  getIt.registerFactory<CalendarBloc>(
    () => CalendarBloc(getIt<CalendarRepository>()),
  );

  // ── Navigation ──────────────────────────────────────────────
  // A factory like the rest. The shell's BlocProvider is the one owner, and
  // the shell is on screen for the life of the app.
  getIt.registerFactory<NavigationBloc>(
    () => NavigationBloc(getIt<BiometricService>()),
  );

  // moarch:registrations — `moarch create feature` and
  // `moarch create bloc` insert each new bloc directly above this line.
  // Move them up into the cascade if you prefer; only the comment has to
  // stay.
}
