import 'injector.dart';

/// The state holders.
///
/// A feature bloc is a **factory**: each screen's `BlocProvider` creates its
/// own and closing the route closes it. Only the session-wide ones — auth,
/// the locale — are singletons, because the router's redirect and every
/// screen have to be reading the same instance.
void registerBlocs() {
  // moarch:registrations — `moarch create feature` and
  // `moarch create bloc` insert each new bloc directly above this line.
  // Move them up into the cascade if you prefer; only the comment has to
  // stay.
}
