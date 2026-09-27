
import '../../core/utils/app_logger.dart';

/// The kind of a failure, as a value rather than a type.
///
/// [AppException.type] is what hands it out. Switching on the exception itself
/// is exhaustive and reads better, so new code rarely needs this — it is here
/// for code written before [AppException] was sealed. If nothing in the
/// project reads `.type`, delete this enum and the getter with it.
enum AppExceptionType { network, server, notFound, auth, cancelled, unknown }

/// Every failure worth showing a user, as one closed family.
///
/// Sealed, so the subclasses below are the whole list: a `switch` over an
/// AppException is checked for completeness, and a kind added later cannot be
/// silently missed at the places that branch on one. Nothing outside this file
/// can join the family, which is what makes that hold.
///
/// Catch the base class wherever all you do is show [message] — which is most
/// places, and what your stack's shell already does for you — `runAction` and
/// `AppAsyncView` on Riverpod, `runAction` and `AppStatusView` on bloc. Catch a
/// subclass where one failure needs its own path:
///
/// ```dart
/// try {
///   await _repo.refresh();
/// } on NetworkException {
///   // Offline says nothing about the session — keep it.
///   return true;
/// } on AppException {
///   await _tokens.clearSession();
///   return false;
/// }
/// ```
///
/// Nothing constructs these by hand: the factories below are the way in, and
/// `safeApiCall` / `safeFirebaseCall` call them at the boundary so that every
/// layer above the datasource sees an AppException and nothing else.
sealed class AppException implements Exception {
  const AppException({required this.message, this.statusCode});

  /// Safe to show as-is: each factory below either writes this message itself
  /// or takes one the backend meant for a user.
  final String message;

  /// The HTTP status behind the failure, where there was one.
  final int? statusCode;

  /// Which kind this is, as a value.
  ///
  /// A `switch` on the exception itself is exhaustive and needs none of this.
  /// Adding a subclass makes the switch below incomplete — that is the
  /// compiler asking you to give the new kind an enum value too.
  AppExceptionType get type => switch (this) {
        NetworkException() => AppExceptionType.network,
        ServerException() => AppExceptionType.server,
        NotFoundException() => AppExceptionType.notFound,
        AuthException() => AppExceptionType.auth,
        CancelledException() => AppExceptionType.cancelled,
        UnknownException() => AppExceptionType.unknown,
      };

  @override
  String toString() =>
      '$runtimeType(message: $message, statusCode: $statusCode)';

  factory AppException.noInternet() =>
      const NetworkException(message: 'No internet connection');

  factory AppException.sessionExpired() =>
      const ServerException(message: 'Session expired', statusCode: 401);

  /// The user dismissed the flow. Nothing failed, so usually show nothing.
  factory AppException.cancelled() =>
      const CancelledException(message: 'Cancelled');

  factory AppException.fromError(Object error, StackTrace stackTrace) {
    final message = error.toString();
        appLogger.e('[AppException] — $message', error: error, stackTrace: stackTrace);
    
    return UnknownException(message: message);
  }


}

/// The request never reached the server — no connection, or it dropped before
/// anything came back. No status code, because there was no response.
final class NetworkException extends AppException {
  const NetworkException({required super.message});
}

/// The server answered, and the answer was a failure.
final class ServerException extends AppException {
  const ServerException({required super.message, super.statusCode});
}

/// What was asked for is not there — a 404, or a document that does not
/// exist. Its own kind because a screen usually draws that as empty rather
/// than as broken.
final class NotFoundException extends AppException {
  const NotFoundException({required super.message, super.statusCode});
}

/// Not signed in, not allowed, or refused credentials — usually the cue to
/// send the user back to login.
final class AuthException extends AppException {
  const AuthException({required super.message, super.statusCode});
}

/// The user backed out: a dismissed sheet, a closed OAuth popup. Nothing
/// failed, so this is the one kind normally shown as nothing at all.
final class CancelledException extends AppException {
  const CancelledException({required super.message});
}

/// Everything the boundary could not identify. [message] is the raw error, so
/// prefer wording of your own over showing it.
final class UnknownException extends AppException {
  const UnknownException({required super.message});
}
