import 'package:flutter/foundation.dart';

/// デバッグビルドのみログを出力するロガー
///
/// リリースビルドでは一切出力しないため、
/// [debugPrint] を直接使う代わりにこちらを使用すること。
class AppLogger {
  AppLogger._();

  static void log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  static void warn(String message) {
    if (kDebugMode) {
      debugPrint('[WARN] $message');
    }
  }

  static void error(String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message${error != null ? ': $error' : ''}');
    }
  }
}
