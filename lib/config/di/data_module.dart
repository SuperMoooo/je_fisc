import 'package:sqflite/sqflite.dart';

import '../../core/services/local_file_store.dart';
import 'injector.dart';
import '../../features/work/data/datasources/work_local_datasource.dart';
import '../../features/work/data/repositories/work_repository_impl.dart';
import '../../features/work/domain/repositories/work_repository.dart';

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
  getIt.registerLazySingleton<WorkRepository>(
    () => WorkRepositoryImpl(getIt<WorkLocalDataSource>()),
  );

  // moarch:registrations — `moarch create feature` inserts each new
  // feature's datasource and repository directly above this line. Move
  // them up into the cascade if you prefer; only the comment has to stay.
}
