import 'package:get_it/get_it.dart';

import 'injector.dart';

/// The long-lived services that belong to one feature rather than to
/// `lib/core`: a socket the chat feature keeps open, a call engine, a sync
/// worker. They live under `lib/features/<feature>/data/services/` and are
/// registered here — not in `core_module.dart`, since no other feature uses
/// them, and not in `data_module.dart`, which is datasources and
/// repositories.
///
/// Give anything that holds a connection a `dispose`, so `getIt.reset()`
/// closes it:
///
/// ```dart
/// getIt.registerLazySingleton<ChatSocket>(
///   () => ChatSocket(getIt<TokenStorage>()),
///   dispose: (socket) => socket.close(),
/// );
/// ```
void registerFeatureServices() {
  // Nothing yet — register a feature's long-lived services here.
}

// ── Scopes ────────────────────────────────────────────────────────────────────
// For what one flow owns rather than the whole app: a call's audio engine, a
// checkout's cart. A singleton would outlive the flow and hold the resource
// for the rest of the session; a factory would build a second one for every
// screen of the same flow. A scope is opened when the flow starts, shared by
// every screen inside it, and disposed when it ends:
//
//   // The first screen of the flow (a bloc's constructor, a page's initState):
//   openScope('call', (scope) {
//     scope.registerSingleton<CallEngine>(
//       CallEngine(),
//       dispose: (engine) => engine.release(),
//     );
//   });
//
//   // When the flow ends (the bloc's close(), the page's dispose):
//   await closeScope('call');

/// Opens the get_it scope [name] and registers what the flow owns in [init].
///
/// A no-op when the scope is already open, so a screen rebuilt or re-entered
/// mid-flow does not stack a second one on top.
void openScope(String name, void Function(GetIt scope) init) {
  if (getIt.hasScope(name)) return;
  getIt.pushNewScope(scopeName: name, init: init);
}

/// Drops the scope [name], disposing everything registered in it. A no-op
/// when it is not open.
Future<void> closeScope(String name) async {
  if (!getIt.hasScope(name)) return;
  await getIt.dropScope(name);
}
