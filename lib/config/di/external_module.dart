import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../core/security/secure_storage.dart';
import 'injector.dart';

/// The instances that are not ours: the HTTP client, the Firebase handles,
/// the platform keystore, the SQLite database.
///
/// Swapping one of these packages out is a change to this file and to the
/// wrappers under `lib/core` — nowhere else.
void registerExternals() {
  getIt
    ..registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(),
    )
    ..registerLazySingleton<TokenStorage>(
      () => TokenStorage(getIt<FlutterSecureStorage>()),
    )
    // Async: the file is opened (and migrated) once, before runApp —
    // `setupInjector` awaits `getIt.allReady()`.
    ..registerSingletonAsync<Database>(
      AppDatabase.open,
      dispose: (db) => db.close(),
    );
}
