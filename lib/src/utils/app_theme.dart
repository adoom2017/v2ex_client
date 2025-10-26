import 'package:flutter/material.dart';
import 'dart:io';

class AppTheme {
  // 根据平台选择合适的字体
  static String get platformFontFamily {
    if (Platform.isIOS || Platform.isMacOS) {
      return 'PingFang SC';
    } else if (Platform.isWindows) {
      return 'Microsoft YaHei';
    } else if (Platform.isAndroid || Platform.isLinux) {
      return 'Noto Sans CJK SC';
    } else {
      return 'Arial'; // Web 或其他平台的回退
    }
  }

  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamilyFallback: const [
      'PingFang SC', // macOS/iOS
      'Microsoft YaHei', // Windows
      'Noto Sans CJK SC', // Android/Linux
      'Arial', // 通用回退
    ],
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    textTheme: const TextTheme(
      // 标题字体统一调整
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.1,
      ),
      // 正文字体统一调整
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.4,
        letterSpacing: 0,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.3,
        letterSpacing: 0,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.2,
        letterSpacing: 0.1,
      ),
      // 标签字体统一调整
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamilyFallback: const [
      'PingFang SC', // macOS/iOS
      'Microsoft YaHei', // Windows
      'Noto Sans CJK SC', // Android/Linux
      'Arial', // 通用回退
    ],
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    textTheme: const TextTheme(
      // 标题字体统一调整
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.1,
      ),
      // 正文字体统一调整
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.4,
        letterSpacing: 0,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.3,
        letterSpacing: 0,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.2,
        letterSpacing: 0.1,
      ),
      // 标签字体统一调整
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
    ),
  );
}
