import 'package:flutter_test/flutter_test.dart';
import 'package:pos/domain/value_objects/order_status.dart';

void main() {
  group('OrderStatus.fromName', () {
    test('각 유효한 statusName으로 올바른 인스턴스 반환', () {
      expect(OrderStatus.fromName('pending'), isA<OrderStatusPending>());
      expect(OrderStatus.fromName('delivered'), isA<OrderStatusDelivered>());
      expect(OrderStatus.fromName('paid'), isA<OrderStatusPaid>());
      expect(OrderStatus.fromName('credited'), isA<OrderStatusCredited>());
      expect(OrderStatus.fromName('cancelled'), isA<OrderStatusCancelled>());
      expect(OrderStatus.fromName('refunded'), isA<OrderStatusRefunded>());
    });

    test('알 수 없는 이름 입력 시 ArgumentError 발생', () {
      expect(
        () => OrderStatus.fromName('unknown'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('OrderStatus name round-trip', () {
    const statuses = [
      OrderStatusPending(),
      OrderStatusDelivered(),
      OrderStatusPaid(),
      OrderStatusCredited(),
      OrderStatusCancelled(),
      OrderStatusRefunded(),
    ];

    for (final status in statuses) {
      test('${status.runtimeType} name round-trip 성공', () {
        final restored = OrderStatus.fromName(status.name);
        expect(restored.name, equals(status.name));
        expect(restored.runtimeType, equals(status.runtimeType));
      });
    }
  });

  group('OrderStatus 개별 name 값', () {
    test('각 상태의 name이 예상 문자열과 일치', () {
      expect(const OrderStatusPending().name, equals('pending'));
      expect(const OrderStatusDelivered().name, equals('delivered'));
      expect(const OrderStatusPaid().name, equals('paid'));
      expect(const OrderStatusCredited().name, equals('credited'));
      expect(const OrderStatusCancelled().name, equals('cancelled'));
      expect(const OrderStatusRefunded().name, equals('refunded'));
    });
  });
}
