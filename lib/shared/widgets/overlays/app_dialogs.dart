import 'package:flutter/material.dart';
import '../../../config/router/app_router.dart';

abstract class IAppDialogs {
  Future<T?> showAppDialog<T>({
    required Widget child,
    bool dismissible = true,
    bool useRootNavigator = true,
    Duration duration = const Duration(milliseconds: 300),
    Color barrierColor = const Color(0x80000000),
  });
}

class AppDialogs implements IAppDialogs {
  @override
  Future<T?> showAppDialog<T>({
    required Widget child,
    bool dismissible = true,
    bool useRootNavigator = true,
    Duration duration = const Duration(milliseconds: 300),
    Color barrierColor = const Color(0x80000000),
  }) async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return null;

    return await showGeneralDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      barrierColor: barrierColor,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: duration,
      useRootNavigator: useRootNavigator,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
