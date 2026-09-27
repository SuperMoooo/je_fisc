
import 'injector.dart';

/// The data layer: each feature's datasources, and the repository
/// implementation bound to the interface its domain layer declares.
///
/// Lazy singletons throughout — one connection's worth of state, shared by
/// every screen that reads it.
void registerDataLayer() {
  // moarch:registrations — `moarch create feature` inserts each new
  // feature's datasource and repository directly above this line. Move
  // them up into the cascade if you prefer; only the comment has to stay.
}
