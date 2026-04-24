import 'package:flutter_test/flutter_test.dart';
import 'package:pos/domain/entities/order_item.dart';

void main() {
  final base = OrderItem(
    id: 'id-1',
    orderId: 'order-1',
    menuItemId: 'menu-1',
    menuName: '김치찌개',
    unitPrice: 9000,
    quantity: 2,
    subtotal: 18000,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  group('OrderItem copyWith', () {
    test('quantity, subtotal 변경', () {
      final updated = base.copyWith(quantity: 3, subtotal: 27000);
      expect(updated.quantity, equals(3));
      expect(updated.subtotal, equals(27000));
      expect(updated.menuName, equals(base.menuName));
    });

    test('인자 없이 호출하면 동일 값 유지', () {
      expect(base.copyWith().unitPrice, equals(base.unitPrice));
    });
  });

  group('OrderItem equality', () {
    test('동일 id이면 동등', () {
      expect(base, equals(base.copyWith(quantity: 5)));
    });

    test('다른 id이면 비동등', () {
      expect(base, isNot(equals(base.copyWith(id: 'id-2'))));
    });

    test('hashCode가 id 기반으로 일관됨', () {
      expect(base.hashCode, equals(base.copyWith(quantity: 5).hashCode));
    });
  });
}
