import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:v2ex_client/src/services/log_service.dart';

class SignInResult {
  final bool success;
  final String? errorMessage;
  final Map<String, String>? cookies;
  final bool requires2FA;

  SignInResult({
    required this.success,
    this.errorMessage,
    this.cookies,
    this.requires2FA = false,
  });
}

/// 登录服务
class SignInService {
  final Dio _dio;

  SignInService(this._dio);

  /// 获取登录页面的once参数和验证码
  Future<String?> getOnceToken() async {
    try {
      LogService.info('Fetching once token from signin page');
      final response = await _dio.get(
        'https://www.v2ex.com/signin',
        options: Options(
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );

      // 从HTML中提取once参数 - 尝试多种模式
      final html = response.data as String;

      // 模式1: name="once" value="数字"
      var onceMatch = RegExp(r'name="once"\s+value="(\d+)"').firstMatch(html);

      // 模式2: value="数字" name="once"
      if (onceMatch == null) {
        onceMatch = RegExp(r'value="(\d+)"\s+name="once"').firstMatch(html);
      }

      // 模式3: 在整个input标签中查找 (单引号或双引号)
      if (onceMatch == null) {
        onceMatch = RegExp(
                r'<input[^>]*name=["\047]once["\047][^>]*value=["\047](\d+)["\047]')
            .firstMatch(html);
      }

      // 模式4: 反向查找
      if (onceMatch == null) {
        onceMatch = RegExp(
                r'<input[^>]*value=["\047](\d+)["\047][^>]*name=["\047]once["\047]')
            .firstMatch(html);
      }

      if (onceMatch != null) {
        final once = onceMatch.group(1);
        LogService.info('Once token retrieved: $once');
        return once;
      }

      LogService.warning('Once token not found in signin page');
      // 输出HTML的一小部分用于调试
      if (html.length > 500) {
        LogService.info('HTML snippet: ${html.substring(0, 500)}...');
      }
      return null;
    } catch (e, stackTrace) {
      LogService.error('Failed to get once token', e, stackTrace);
      return null;
    }
  }

  /// 执行登录
  Future<SignInResult> signIn({
    required String username,
    required String password,
    required String captcha,
    required String once,
  }) async {
    try {
      LogService.info('Attempting to sign in', {'username': username});

      // 准备表单数据
      final formData = FormData.fromMap({
        'u': username,
        'p': password,
        'captcha': captcha,
        'once': once,
        'next': '/',
      });

      // 第一步：发送登录请求（不跟随重定向）
      final response = await _dio.post(
        'https://www.v2ex.com/signin',
        data: formData,
        options: Options(
          followRedirects: false,
          validateStatus: (status) => status! < 500,
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );

      // 提取初始cookies
      final cookies = _extractCookies(response);

      // 检查第一次重定向
      if (response.statusCode == 302 || response.statusCode == 301) {
        final location = response.headers['location']?.first ?? '';
        LogService.info('First redirect to: $location');

        // 如果直接重定向到/2fa，说明需要2FA
        if (location.contains('/2fa')) {
          LogService.info('Direct 2FA redirect detected');
          return SignInResult(
            success: false,
            requires2FA: true,
            cookies: cookies,
          );
        }

        // 如果重定向到首页，需要跟随重定向检查是否会再次重定向到/2fa
        if (location == '/' ||
            location.contains('v2ex.com/') ||
            location.contains('v2ex.com')) {
          LogService.info('Checking if homepage redirects to 2FA');

          // 第二步：访问首页，看是否会重定向到/2fa
          final cookieString =
              cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');

          final homeResponse = await _dio.get(
            'https://www.v2ex.com/',
            options: Options(
              followRedirects: false,
              validateStatus: (status) => status! < 500,
              headers: {
                'Cookie': cookieString,
              },
            ),
          );

          // 提取新的cookies并合并
          final newCookies = _extractCookies(homeResponse);
          cookies.addAll(newCookies);

          // 检查是否重定向到2FA
          if (homeResponse.statusCode == 302 ||
              homeResponse.statusCode == 301) {
            final secondLocation =
                homeResponse.headers['location']?.first ?? '';
            LogService.info('Second redirect to: $secondLocation');

            if (secondLocation.contains('/2fa')) {
              LogService.info(
                  '2FA verification required (detected on second redirect)');
              return SignInResult(
                success: false,
                requires2FA: true,
                cookies: cookies,
              );
            }
          }

          // 没有重定向到2FA，登录成功
          if (cookies.isNotEmpty) {
            LogService.info('Sign in successful (no 2FA required)');
            return SignInResult(
              success: true,
              cookies: cookies,
            );
          }
        }

        // 其他重定向情况，如果有cookies就认为成功
        if (cookies.isNotEmpty) {
          LogService.info('Sign in successful');
          return SignInResult(
            success: true,
            cookies: cookies,
          );
        }
      }

      // 检查是否有错误消息
      if (response.data is String) {
        final html = response.data as String;

        // 检查常见错误
        if (html.contains('用户名和密码无法匹配')) {
          return SignInResult(
            success: false,
            errorMessage: '用户名和密码无法匹配',
          );
        } else if (html.contains('验证码不正确')) {
          return SignInResult(
            success: false,
            errorMessage: '验证码不正确',
          );
        } else if (html.contains('请输入验证码')) {
          return SignInResult(
            success: false,
            errorMessage: '请输入验证码',
          );
        }
      }

      LogService.warning('Sign in failed with unknown error');
      return SignInResult(
        success: false,
        errorMessage: '登录失败，请重试',
      );
    } catch (e, stackTrace) {
      LogService.error('Sign in error', e, stackTrace);
      return SignInResult(
        success: false,
        errorMessage: '网络错误：${e.toString()}',
      );
    }
  }

  /// 获取2FA页面的once token
  Future<String?> get2FAOnceToken(String cookies) async {
    try {
      LogService.info('Fetching 2FA once token');
      final response = await _dio.get(
        'https://www.v2ex.com/2fa',
        options: Options(
          followRedirects: true,
          validateStatus: (status) => status! < 500,
          headers: {
            'Cookie': cookies,
          },
        ),
      );

      // 从HTML中提取once参数
      final html = response.data as String;

      // 尝试多种模式提取once
      var onceMatch = RegExp(r'name="once"\s+value="(\d+)"').firstMatch(html);

      if (onceMatch == null) {
        onceMatch = RegExp(r'value="(\d+)"\s+name="once"').firstMatch(html);
      }

      if (onceMatch != null) {
        final once = onceMatch.group(1);
        LogService.info('2FA once token retrieved: $once');
        return once;
      }

      LogService.warning('2FA once token not found');
      return null;
    } catch (e, stackTrace) {
      LogService.error('Failed to get 2FA once token', e, stackTrace);
      return null;
    }
  }

  /// 提交2FA验证码
  Future<SignInResult> verify2FA({
    required String code,
    required String once,
    required String cookies,
  }) async {
    try {
      LogService.info('Verifying 2FA code');

      // 准备表单数据
      final formData = FormData.fromMap({
        'code': code,
        'once': once,
      });

      // 发送2FA验证请求
      final response = await _dio.post(
        'https://www.v2ex.com/2fa',
        data: formData,
        options: Options(
          followRedirects: false,
          validateStatus: (status) => status! < 500,
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Cookie': cookies,
          },
        ),
      );

      // 检查响应
      if (response.statusCode == 302 || response.statusCode == 301) {
        // 验证成功，重定向
        final newCookies = _extractCookies(response);

        // 合并旧的和新的cookies
        final allCookies = <String, String>{};

        // 解析旧cookies
        for (final cookie in cookies.split('; ')) {
          final parts = cookie.split('=');
          if (parts.length == 2) {
            allCookies[parts[0]] = parts[1];
          }
        }

        // 添加新cookies
        allCookies.addAll(newCookies);

        if (allCookies.isNotEmpty) {
          LogService.info('2FA verification successful');
          return SignInResult(
            success: true,
            cookies: allCookies,
          );
        }
      }

      // 检查是否有错误消息
      if (response.data is String) {
        final html = response.data as String;

        if (html.contains('两步验证码不正确')) {
          return SignInResult(
            success: false,
            errorMessage: '两步验证码不正确',
          );
        } else if (html.contains('验证码已过期')) {
          return SignInResult(
            success: false,
            errorMessage: '验证码已过期，请重新登录',
          );
        }
      }

      LogService.warning('2FA verification failed with unknown error');
      return SignInResult(
        success: false,
        errorMessage: '验证失败，请重试',
      );
    } catch (e, stackTrace) {
      LogService.error('2FA verification error', e, stackTrace);
      return SignInResult(
        success: false,
        errorMessage: '网络错误：${e.toString()}',
      );
    }
  }

  /// 从响应中提取Cookie
  Map<String, String> _extractCookies(Response response) {
    final cookies = <String, String>{};
    final cookieHeaders = response.headers['set-cookie'];

    if (cookieHeaders != null) {
      for (final cookie in cookieHeaders) {
        final parts = cookie.split(';');
        if (parts.isNotEmpty) {
          final cookieParts = parts[0].split('=');
          if (cookieParts.length == 2) {
            cookies[cookieParts[0]] = cookieParts[1];
          }
        }
      }
    }

    return cookies;
  }
}

final signInServiceProvider = Provider<SignInService>((ref) {
  return SignInService(Dio());
});
