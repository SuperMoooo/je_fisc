import 'package:bloc/bloc.dart';

import 'app_logger.dart';

final _log = appLogger.scoped('Bloc');

/// Logs what a bloc hands to `addError` — `runAction` does so for anything
/// that is not an `AppException`, so an unexpected failure is not lost behind
/// the generic message it shows. An error thrown out of an event handler
/// lands here too.
///
/// Installed once, in `main.dart`: `Bloc.observer = const AppBlocObserver();`
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    _log.e('${bloc.runtimeType} failed', error: error, stackTrace: stackTrace);
    super.onError(bloc, error, stackTrace);
  }
}
