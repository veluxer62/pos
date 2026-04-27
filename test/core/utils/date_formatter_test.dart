import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/utils/date_formatter.dart';

void main() {
  final dt = DateTime(2024, 4, 5, 9, 7);

  group('DateFormatter', () {
    test('formatDate: yyyy.MM.dd 형식으로 반환한다', () {
      expect(DateFormatter.formatDate(dt), '2024.04.05');
    });

    test('formatDateTime: yyyy.MM.dd HH:mm 형식으로 반환한다', () {
      expect(DateFormatter.formatDateTime(dt), '2024.04.05 09:07');
    });

    test('formatTime: HH:mm 형식으로 반환한다', () {
      expect(DateFormatter.formatTime(dt), '09:07');
    });

    test('월/일/시/분이 한 자리일 때 0을 채운다', () {
      final single = DateTime(2024, 1, 3, 8, 5);
      expect(DateFormatter.formatDate(single), '2024.01.03');
      expect(DateFormatter.formatTime(single), '08:05');
    });
  });
}
