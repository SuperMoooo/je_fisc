import '../../core/security/biometric_service.dart';
import '../../core/services/media_service.dart';
import '../../core/services/permission_service.dart';
import 'injector.dart';

/// The app's own cross-cutting services — what lives under `lib/core` because
/// no single feature owns it.
///
/// A service you write by hand belongs here too. Nothing regenerates this
/// file once the project exists; `moarch update` only refreshes it, and tells
/// you first if you have edited it.
void registerCoreServices() {
  getIt
    ..registerLazySingleton<PermissionService>(PermissionService.new)
    ..registerLazySingleton<MediaService>(
        () => MediaService(getIt<PermissionService>()))
    ..registerLazySingleton<BiometricService>(BiometricService.new);
}
