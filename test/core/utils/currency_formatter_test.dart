import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    test('0원을 올바르게 포맷한다', () {
      expect(CurrencyFormatter.format(0), '0원');
    });

    test('세 자리 미만은 쉼표 없이 포맷한다', () {
      expect(CurrencyFormatter.format(500), '500원');
    });

    test('1,000원을 올바르게 포맷한다', () {
      expect(CurrencyFormatter.format(1000), '1,000원');
    });

    test('10,000원을 올바르게 포맷한다', () {
      expect(CurrencyFormatter.format(10000), '10,000원');
    });

    test('1,000,000원을 올바르게 포맷한다', () {
      expect(CurrencyFormatter.format(1000000), '1,000,000원');
    });

    test('음수 금액을 올바르게 포맷한다', () {
      expect(CurrencyFormatter.format(-5000), '-5,000원');
    });
  });
}
