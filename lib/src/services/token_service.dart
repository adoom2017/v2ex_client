import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:v2ex_client/src/services/log_service.dart';

class TokenService {
  final FlutterSecureStorage _storage;
  static const _tokenKey = 'v2ex_pat';

  TokenService(this._storage);

  Future<String?> getToken() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token != null) {
      } else {
        LogService.tokenOperation('No token found in storage');
      }
      return token;
    } catch (e, stackTrace) {
      LogService.error('❌ Failed to retrieve token from storage', e, stackTrace);
      return null;
    }
  }

  Future<void> setToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      LogService.tokenOperation('Token saved successfully', 'Length: ${token.length}');
    } catch (e, stackTrace) {
      LogService.error('❌ Failed to save token to storage', e, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteToken() async {
    try {
      await _storage.delete(key: _tokenKey);
      LogService.tokenOperation('Token deleted successfully');
    } catch (e, stackTrace) {
      LogService.error('❌ Failed to delete token from storage', e, stackTrace);
      rethrow;
    }
  }
}

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final tokenServiceProvider = Provider<TokenService>((ref) {
  return TokenService(ref.watch(secureStorageProvider));
});
