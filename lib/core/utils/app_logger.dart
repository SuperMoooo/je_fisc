import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// The app's logger — call sites talk to this, not to the `logger` package.
final appLogger = AppLogger._();

class AppLogger {
  AppLogger._([this._tag]);

  final String? _tag;

  /// A logger that stamps every record with `[name]`, so logs stay filterable.
  ///
  /// ```dart
  /// final _log = appLogger.scoped('FCM');
  /// _log.i('Token refreshed'); // [FCM] Token refreshed
  /// ```
  AppLogger scoped(String name) => AppLogger._(name);

  /// The noisiest level — debug builds only.
  void t(String message, {Object? error, StackTrace? stackTrace}) =>
      _write(Level.trace, message, error, stackTrace);

  void d(String message, {Object? error, StackTrace? stackTrace}) =>
      _write(Level.debug, message, error, stackTrace);

  void i(String message, {Object? error, StackTrace? stackTrace}) =>
      _write(Level.info, message, error, stackTrace);

  void w(String message, {Object? error, StackTrace? stackTrace}) =>
      _write(Level.warning, message, error, stackTrace);

  void e(String message, {Object? error, StackTrace? stackTrace}) =>
      _write(Level.error, message, error, stackTrace);

  void _write(
    Level level,
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    _logger.log(
      level,
      _tag == null ? message : '[$_tag] $message',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

final _logger = Logger(
  // One line per record in release — it is headed for Crashlytics breadcrumbs
  // and device logs, where PrettyPrinter's box art is only noise.
  printer: kReleaseMode
      ? SimplePrinter(printTime: true, colors: false)
      : PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 12,
          colors: true,
          printEmojis: true,
          dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
        ),
  output: MultiOutput(_sinks),
  // Warnings and errors survive into release; use Level.off to silence it.
  level: kReleaseMode ? Level.warning : Level.trace,
);

/// Writes through `dart:developer`, so DevTools' Logging view gets one
/// filterable record per event instead of a wall of console text.
class _DeveloperOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    developer.log(
      _redact(event.lines.join('\n')),
      name: 'app',
      time: event.origin.time,
      level: _developerLevels[event.level] ?? 0,
    );
  }
}

/// `dart:developer` grades severity on package:logging's scale, which [Level]
/// does not line up with.
const _developerLevels = <Level, int>{
  Level.trace: 300,
  Level.debug: 500,
  Level.info: 800,
  Level.warning: 900,
  Level.error: 1000,
  Level.fatal: 1200,
};

/// Every sink runs this, so a stray `appLogger.d(response.data.toString())`
/// cannot put a credential in the logs.
final _sensitiveKeyPattern = RegExp(
  r'("?(?:password|newPassword|token|authorization|refreshToken|accessToken)"?\s*:\s*)'
  r'("[^"]*"|[^,}\]\n]+)',
  caseSensitive: false,
);

final _bearerPattern = RegExp(r'Bearer\s+\S+', caseSensitive: false);

String _redact(String message) => message
    .replaceAllMapped(
      _sensitiveKeyPattern,
      (match) => '${match.group(1)}***REDACTED***',
    )
    .replaceAll(_bearerPattern, 'Bearer ***REDACTED***');

final _sinks = <LogOutput>[_DeveloperOutput()];
