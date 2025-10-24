import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

class LogService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2, // 显示方法调用栈的数量
      errorMethodCount: 8, // 错误时显示更多的调用栈
      lineLength: 120, // 每行的长度
      colors: true, // 彩色输出
      printEmojis: true, // 显示表情符号
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart, // 显示时间戳
    ),
    level: Level.info, // 设置日志级别
  );

  // Debug 级别日志
  static void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  // Info 级别日志
  static void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  // Warning 级别日志
  static void warning(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  // Error 级别日志
  static void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  // Fatal 级别日志
  static void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  // API 请求日志
  static void apiRequest(String method, String url, [Map<String, dynamic>? data]) {
    _logger.d('🌐 API Request: $method $url', error: data);
  }

  // API 响应日志
  static void apiResponse(String method, String url, int statusCode, [dynamic data]) {
    if (statusCode >= 200 && statusCode < 300) {
      _logger.d('✅ API Response: $method $url - $statusCode');
    } else {
      _logger.w('⚠️ API Response: $method $url - $statusCode', error: data);
    }
  }

  // API 错误日志
  static void apiError(String method, String url, dynamic error, [StackTrace? stackTrace]) {
    _logger.e('❌ API Error: $method $url', error: error, stackTrace: stackTrace);
  }

  // Token 相关日志
  static void tokenOperation(String operation, [String? details]) {
    _logger.d('🔑 Token Operation: $operation ${details ?? ''}');
  }

  // 用户操作日志
  static void userAction(String action, [Map<String, dynamic>? context]) {
    _logger.d('👤 User Action: $action', error: context);
  }
}

final logServiceProvider = Provider<LogService>((ref) {
  return LogService();
});