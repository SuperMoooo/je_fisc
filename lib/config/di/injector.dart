import 'package:get_it/get_it.dart';

import 'core_module.dart';
import 'data_module.dart';
import 'external_module.dart';
import 'feature_module.dart';
import 'presentation_module.dart';

/// The service locator. Everything long-lived is registered through
/// `setupInjector` and pulled out with `getIt<Thing>()`.
///
/// The registrations themselves are one file per layer, so this one does not
/// grow with the app:
///
/// - `external_module.dart` — Dio, Firebase, secure storage.
/// - `core_module.dart` — the services under `lib/core`.
/// - `data_module.dart` — datasources and repositories.
/// - `feature_module.dart` — long-lived services a feature owns.
/// - `presentation_module.dart` — blocs.
///
/// Each of those imports this file back for [getIt]. That is a cycle on paper
/// and nothing at all in practice — Dart resolves it fine, and it is what
/// lets every other file in the project go on importing one well-known path
/// for the locator.
///
/// Blocs are the exception worth knowing: a feature bloc is registered as a
/// **factory**, so each screen gets its own and closing the route disposes
/// it. Only session-wide blocs (auth) are singletons.
final getIt = GetIt.instance;

/// Wires the app up. Called from `main()` after `Firebase.initializeApp()`
/// and before `runApp`.
///
/// In a widget test, call `getIt.reset()` first and register fakes for the
/// pieces under test — nothing here reaches for a real service on its own.
Future<void> setupInjector() async {
  // The order is a readability choice, not a requirement: every registration
  // is lazy, so a layer may depend on one registered after it.
  registerExternals();
  registerCoreServices();
  registerDataLayer();
  registerFeatureServices();
  registerBlocs();

  // Everything above is lazy, so nothing has been constructed yet. Await this
  // if you later register an async singleton (registerSingletonAsync).
  await getIt.allReady();
}
