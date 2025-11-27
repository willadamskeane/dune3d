import 'package:flutter_test/flutter_test.dart';
import 'package:cad_app/src/core/logger.dart';

void main() {
  group('AppLogger', () {
    test('debug log does not throw', () {
      expect(() => AppLogger.d('test message'), returnsNormally);
    });

    test('debug log with custom tag does not throw', () {
      expect(() => AppLogger.d('test message', tag: 'CUSTOM'), returnsNormally);
    });

    test('error log does not throw', () {
      expect(() => AppLogger.e('error message'), returnsNormally);
    });

    test('error log with exception does not throw', () {
      expect(
        () => AppLogger.e(
          'error message',
          error: Exception('test'),
          stackTrace: StackTrace.current,
        ),
        returnsNormally,
      );
    });

    test('info log does not throw', () {
      expect(() => AppLogger.i('info message'), returnsNormally);
    });

    test('warning log does not throw', () {
      expect(() => AppLogger.w('warning message'), returnsNormally);
    });
  });
}
