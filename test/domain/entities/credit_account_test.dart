import 'package:flutter_test/flutter_test.dart';
import 'package:pos/domain/entities/credit_account.dart';

void main() {
  final base = CreditAccount(
    id: 'id-1',
    customerName: '홍길동',
    balance: 15000,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  group('CreditAccount copyWith', () {
    test('balance 변경', () {
      final updated = base.copyWith(balance: 30000);
      expect(updated.balance, equals(30000));
      expect(updated.customerName, equals(base.customerName));
    });

    test('인자 없이 호출하면 동일 값 유지', () {
      expect(base.copyWith().balance, equals(base.balance));
    });
  });

  group('CreditAccount equality', () {
    test('동일 id이면 동등', () {
      expect(base, equals(base.copyWith(balance: 0)));
    });

    test('다른 id이면 비동등', () {
      expect(base, isNot(equals(base.copyWith(id: 'id-2'))));
    });

    test('hashCode가 id 기반으로 일관됨', () {
      expect(base.hashCode, equals(base.copyWith(balance: 0).hashCode));
    });
  });
}
