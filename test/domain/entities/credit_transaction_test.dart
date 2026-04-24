import 'package:flutter_test/flutter_test.dart';
import 'package:pos/domain/entities/credit_transaction.dart';
import 'package:pos/domain/value_objects/credit_transaction_type.dart';

void main() {
  final base = CreditTransaction(
    id: 'id-1',
    creditAccountId: 'ca-1',
    type: CreditTransactionType.charge,
    amount: 15000,
    createdAt: DateTime(2026),
    orderId: 'order-1',
  );

  group('CreditTransaction copyWith', () {
    test('amount 변경', () {
      final updated = base.copyWith(amount: 20000);
      expect(updated.amount, equals(20000));
      expect(updated.type, equals(base.type));
    });

    test('orderId를 null로 되돌릴 수 있음 (sentinel 패턴)', () {
      expect(base.copyWith(orderId: null).orderId, isNull);
    });

    test('note를 설정하고 null로 되돌릴 수 있음', () {
      final withNote = base.copyWith(note: '메모');
      expect(withNote.note, equals('메모'));
      expect(withNote.copyWith(note: null).note, isNull);
    });

    test('인자 없이 호출하면 orderId 유지', () {
      expect(base.copyWith().orderId, equals(base.orderId));
    });
  });

  group('CreditTransaction equality', () {
    test('동일 id이면 동등', () {
      expect(base, equals(base.copyWith(amount: 99999)));
    });

    test('다른 id이면 비동등', () {
      expect(base, isNot(equals(base.copyWith(id: 'id-2'))));
    });

    test('hashCode가 id 기반으로 일관됨', () {
      expect(base.hashCode, equals(base.copyWith(amount: 99999).hashCode));
    });
  });
}
