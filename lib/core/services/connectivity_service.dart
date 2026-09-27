import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:bloc/bloc.dart';

import '../utils/app_logger.dart';

final _log = appLogger.scoped('Connectivity');

/// The connection as bloc state: `true` while online.
///
/// `OfflineGate` provides one above the navigator, so any screen can
/// `context.watch<ConnectivityCubit>()`. Without the gate, provide it where
/// it is needed. It starts online and fails open, like the gate.
///
/// A Cubit, not a Bloc: it holds one flag and has no events. It lives beside
/// the service it reads rather than in a `connectivity_cubit.dart` of its own
/// — which is the naming rule waived below.
// ignore: prefer_file_naming_conventions
class ConnectivityCubit extends Cubit<bool> {
  ConnectivityCubit(this._service) : super(true) {
    _subscription = _service.hasInternetStream.listen(emit);
  }

  final ConnectivityService _service;
  late final StreamSubscription<bool> _subscription;

  /// Reads the connection again, for a change the platform was slow to
  /// report — the offline screen's retry.
  Future<void> recheck() async => emit(await _service.hasInternet());

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}

/// Whether the device has a network connection, and what to do when it comes
/// back.
///
/// A connection is a network interface, not a working internet: a captive
/// portal or a dead router reads as online. So this decides what to show,
/// never whether to try — a request still handles `NetworkException`.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// `true` while online: the current state first, then each change. The
  /// platform reports every interface switch (wifi to mobile), so repeats
  /// are dropped.
  Stream<bool> get hasInternetStream => _states().distinct();

  Stream<bool> _states() async* {
    yield await hasInternet();
    yield* _connectivity.onConnectivityChanged.map((results) {
      _log.d('$results');
      return _isOnline(results);
    });
  }

  Future<bool> hasInternet() async =>
      _isOnline(await _connectivity.checkConnectivity());

  /// Runs [action] each time the device comes back online — only on the way
  /// back from offline, never on start. Sync what was saved while offline,
  /// retry what failed.
  ///
  /// `main.dart` has the app-wide hook. A feature that owns its own sync can
  /// subscribe too, and cancels the subscription when it goes away:
  ///
  /// ```dart
  /// _reconnect = getIt<ConnectivityService>().onReconnect(_repo.flushQueue);
  /// // in close() / dispose():
  /// _reconnect.cancel();
  /// ```
  StreamSubscription<bool> onReconnect(FutureOr<void> Function() action) {
    bool? previous;
    return hasInternetStream.listen((online) {
      final cameBack = previous == false && online;
      previous = online;
      if (!cameBack) return;
      // The action's errors are its own, but a failed sync must not vanish.
      unawaited(
        Future.sync(action).catchError((Object error, StackTrace stackTrace) {
          _log.e('Reconnect task failed', error: error, stackTrace: stackTrace);
        }),
      );
    });
  }

  static bool _isOnline(List<ConnectivityResult> results) =>
      !results.contains(ConnectivityResult.none);
}
