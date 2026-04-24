import 'package:flutter_test/flutter_test.dart';
import 'package:pos/domain/entities/order.dart';
import 'package:pos/domain/value_objects/order_status.dart';
import 'package:pos/domain/value_objects/payment_type.dart';

void main() {
  final base = Order(
    id: 'id-1',
    businessDayId: 'bd-1',
    seatId: 'seat-1',
    status: const OrderStatusPending(),
    totalAmount: 18000,
    orderedAt: DateTime(2026),
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  group('Order copyWith — required 필드', () {
    test('status 변경', () {
      final updated = base.copyWith(status: const OrderStatusDelivered());
      expect(updated.status, isA<OrderStatusDelivered>());
      expect(updated.totalAmount, equals(base.totalAmount));
    });
  });

  group('Order copyWith — nullable 필드 sentinel', () {
    test('deliveredAt을 값으로 설정', () {
      final t = DateTime(2026, 4, 23, 12);
      expect(base.copyWith(deliveredAt: t).deliveredAt, equals(t));
    });

    test('deliveredAt을 null로 되돌릴 수 있음', () {
      final withDelivered = base.copyWith(deliveredAt: DateTime(2026));
      expect(withDelivered.copyWith(deliveredAt: null).deliveredAt, isNull);
    });

    test('paymentType을 값으로 설정', () {
      final updated = base.copyWith(paymentType: PaymentType.immediate);
      expect(updated.paymentType, equals(PaymentType.immediate));
    });

    test('paymentType을 null로 되돌릴 수 있음', () {
      final withType = base.copyWith(paymentType: PaymentType.credit);
      expect(withType.copyWith(paymentType: null).paymentType, isNull);
    });

    test('creditAccountId을 null로 되돌릴 수 있음', () {
      final withId = base.copyWith(creditAccountId: 'ca-1');
      expect(withId.copyWith(creditAccountId: null).creditAccountId, isNull);
    });

    test('인자 없이 호출하면 nullable 필드 유지', () {
      final withDelivered = base.copyWith(deliveredAt: DateTime(2026));
      expect(withDelivered.copyWith().deliveredAt, equals(DateTime(2026)));
    });
  });

  group('Order equality', () {
    test('동일 id이면 동등', () {
      expect(base, equals(base.copyWith(totalAmount: 9000)));
    });

    test('다른 id이면 비동등', () {
      expect(base, isNot(equals(base.copyWith(id: 'id-2'))));
    });

    test('hashCode가 id 기반으로 일관됨', () {
      expect(base.hashCode, equals(base.copyWith(totalAmount: 9000).hashCode));
    });
  });
}
