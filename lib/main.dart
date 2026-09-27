import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'config/di/injector.dart';
import 'config/router/app_router.dart';
import 'config/theme/app_theme.dart';
import 'core/utils/app_bloc_observer.dart';
import 'core/utils/app_logger.dart';
import 'shared/widgets/error_view.dart';
import 'shared/widgets/mo_adapt.dart';

Future<void> main() async {
  // Preserve the splash before anything else runs.
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Installed before the first await that can fail, so nothing on the way to
  // runApp() dies unreported.
  PlatformDispatcher.instance.onError = (error, st) {
    appLogger.e('[Uncaught error]', error: error, stackTrace: st);
    if (kDebugMode) return false; // false = let Flutter crash normally in dev
    return true; // true = swallow in prod, app stays alive
  };

  FlutterError.onError = (details) {
    appLogger.e(
      '[Flutter error]',
      error: details.exception,
      stackTrace: details.stack,
    );
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  };

  ErrorWidget.builder = (details) {
    if (kDebugMode) return ErrorWidget(details.exception);
    return const Scaffold(body: ErrorView());
  };

  // What a bloc hands to addError — runAction does, for anything that is not
  // an AppException — reaches the logger instead of vanishing.
  Bloc.observer = const AppBlocObserver();

  // Registers every repository, datasource, service and bloc. Firebase is up
  // by this point, so the locator can hand out its instances.
  await setupInjector();

  runApp(
    const MoAdapt(
      // The frame the UI is designed against; every fixed dimension scales
      // proportionally from it. Tune with scaleMode / minScale / maxScale.
      designSize: Size(412, 924),
      child: App(),
    ),
  );

  // After runApp, so the native splash gives way to a painted first frame
  // rather than a blank window. Push it later still — into your own async
  // init, or a post-frame callback — if something has to land before the app
  // is on screen.
  FlutterNativeSplash.remove();
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'JE FISC',
      // One brand theme. `moarch create theme --dark` adds the dark half.
      theme: AppTheme.light,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // Follow the system font size. The cap keeps fixed-height rows
            // and buttons from breaking; it also overrides an accessibility
            // setting, so raise it as far as your layouts survive rather
            // than lowering it.
            textScaler: MediaQuery.textScalerOf(
              context,
            ).clamp(maxScaleFactor: 1.3),
            alwaysUse24HourFormat: true,
          ),
          child: child!,
        );
      },
    );
  }
}
