import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Single owner of the auth session kept in secure storage — used by the Dio
/// client and by the auth repository.
class TokenStorage {
  const TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const accessTokenKey = 'access_token';
  static const refreshTokenKey = 'refresh_token';
  static const userIdKey = 'user_id';

  Future<String?> get accessToken => _storage.read(key: accessTokenKey);
  Future<String?> get refreshToken => _storage.read(key: refreshTokenKey);
  Future<String?> get userId => _storage.read(key: userIdKey);

  /// Saves both tokens plus the user id extracted from the access token.
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: accessTokenKey, value: accessToken);
    await _storage.write(key: refreshTokenKey, value: refreshToken);
    final userId = _userIdFromJwt(accessToken);
    if (userId != null) {
      await _storage.write(key: userIdKey, value: userId);
    }
  }

  Future<void> clearSession() async {
    await _storage.delete(key: accessTokenKey);
    await _storage.delete(key: refreshTokenKey);
    await _storage.delete(key: userIdKey);
  }

  /// Reads the user id claim from the JWT payload. The signature is not
  /// verified — that is the backend's job.
  String? _userIdFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      // Adjust the claim name to whatever your backend puts the user id in.
      final id = payload['sub'] ?? payload['userId'] ?? payload['id'];
      return id?.toString();
    } catch (_) {
      return null;
    }
  }
}
