import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/types/auth_messages_ios.dart';

import '../utils/app_logger.dart';

class BiometricService {
  BiometricService([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;
  // True when the device has a lock screen, biometrics enrolled or not.
  Future<bool> canAuthenticate() => _auth.isDeviceSupported();

  Future<bool> authenticate() {
    return _auth.authenticate(
      localizedReason: 'Please authenticate to continue',
      biometricOnly: false,
      authMessages: const <AuthMessages>[
        AndroidAuthMessages(
          signInTitle: 'Authentication required',
          cancelButton: 'Cancel',
        ),
        IOSAuthMessages(cancelButton: 'Cancel'),
      ],
    );
  }

  /// Runs local authentication, reporting failure as a snackbar rather than
  /// throwing, so callers only need the bool.
  Future<bool> verifyUserLocalAuth() async {
    try {
      final didAuthenticate = await authenticate();
      if (!didAuthenticate) {
        return false;
      }
      return true;
    } on LocalAuthException catch (e) {
      appLogger.e('LocalAuthException: ${e.code.name} - ${e.description}');

      return false;
    } on PlatformException catch (e) {
      appLogger.e('PlatformException: ${e.message}');

      return false;
    }
  }
}
