import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:v2ex_client/src/services/log_service.dart';

/// Cookie管理服务
class CookieService {
  static const String _cookieKey = 'v2ex_cookies';
  final FlutterSecureStorage _storage;

  CookieService(this._storage);

  /// 保存Cookie
  Future<void> saveCookies(String cookies) async {
    try {
      await _storage.write(key: _cookieKey, value: cookies);
      LogService.info('Cookies saved successfully');
    } catch (e, stackTrace) {
      LogService.error('Failed to save cookies', e, stackTrace);
      rethrow;
    }
  }

  /// 获取Cookie
  Future<String?> getCookies() async {
    try {
      final cookies = await _storage.read(key: _cookieKey);
      if (cookies != null) {
        LogService.info('Cookies retrieved successfully');
      }
      return cookies;
    } catch (e, stackTrace) {
      LogService.error('Failed to get cookies', e, stackTrace);
      return null;
    }
  }

  /// 删除Cookie
  Future<void> deleteCookies() async {
    try {
      await _storage.delete(key: _cookieKey);
      LogService.info('Cookies deleted successfully');
    } catch (e, stackTrace) {
      LogService.error('Failed to delete cookies', e, stackTrace);
      rethrow;
    }
  }

  /// 检查是否已登录（有Cookie）
  Future<bool> isLoggedIn() async {
    final cookies = await getCookies();
    return cookies != null && cookies.isNotEmpty;
  }
}

final cookieServiceProvider = Provider<CookieService>((ref) {
  return CookieService(const FlutterSecureStorage());
});
