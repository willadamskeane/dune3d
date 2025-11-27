import 'dart:developer' as developer;

class AppLogger {
  AppLogger._();

  static void d(String message, {String tag = 'DEBUG'}) {
    developer.log(message, name: tag);
  }

  static void e(
    String message, {
    String tag = 'ERROR',
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: tag,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void i(String message, {String tag = 'INFO'}) {
    developer.log(message, name: tag, level: 800);
  }

  static void w(String message, {String tag = 'WARN'}) {
    developer.log(message, name: tag, level: 900);
  }
}
