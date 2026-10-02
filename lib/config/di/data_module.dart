import 'package:sqflite/sqflite.dart';

import '../../core/services/local_file_store.dart';
import 'injector.dart';
import '../../features/work/data/datasources/work_local_datasource.dart';
import '../../features/work/data/datasources/work_report_datasource.dart';
import '../../features/work/data/repositories/work_repository_impl.dart';
import '../../features/work/domain/repositories/work_repository.dart';
import '../../features/category/data/datasources/category_local_datasource.dart';
import '../../features/category/data/repositories/category_repository_impl.dart';
import '../../features/category/domain/repositories/category_repository.dart';
import '../../features/calendar/data/datasources/calendar_local_datasource.dart';
import '../../features/calendar/data/repositories/calendar_repository_impl.dart';
import '../../features/calendar/domain/repositories/calendar_repository.dart';

/// The data layer: each feature's datasources, and the repository
/// implementation bound to the interface its domain layer declares.
///
/// Lazy singletons throughout — one connection's worth of state, shared by
/// every screen that reads it.
void registerDataLayer() {
  // ── Work ────────────────────────────────────────────────────
  getIt.registerLazySingleton<WorkLocalDataSource>(
    () => WorkLocalDataSource(getIt<Database>(), getIt<LocalFileStore>()),
  );
  getIt.registerLazySingleton<WorkReportDataSource>(WorkReportDataSource.new);
  getIt.registerLazySingleton<WorkRepository>(
    () => WorkRepositoryImpl(
      getIt<WorkLocalDataSource>(),
      getIt<WorkReportDataSource>(),
    ),
  );

  // ── Category ────────────────────────────────────────────────
  getIt.registerLazySingleton<CategoryLocalDataSource>(
    () => CategoryLocalDataSource(getIt<Database>()),
  );
  getIt.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(getIt<CategoryLocalDataSource>()),
  );

  // ── Calendar ────────────────────────────────────────────────
  getIt.registerLazySingleton<CalendarLocalDataSource>(
    () => CalendarLocalDataSource(getIt<Database>()),
  );
  getIt.registerLazySingleton<CalendarRepository>(
    () => CalendarRepositoryImpl(getIt<CalendarLocalDataSource>()),
  );

  // moarch:registrations — `moarch create feature` inserts each new
  // feature's datasource and repository directly above this line. Move
  // them up into the cascade if you prefer; only the comment has to stay.
}
