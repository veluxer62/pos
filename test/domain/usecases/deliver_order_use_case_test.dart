import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pos/domain/entities/order.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';
import 'package:pos/domain/repositories/i_order_repository.dart';
import 'package:pos/domain/usecases/order/deliver_order_use_case.dart';
import 'package:pos/domain/value_objects/order_status.dart';

import 'deliver_order_use_case_test.mocks.dart';

@GenerateMocks([IOrderRepository])
void main() {
  late MockIOrderRepository mockOrderRepo;
  late DeliverOrderUseCase sut;

  final pendingOrder = Order(
    id: 'order-1',
    businessDayId: 'bd-1',
    seatId: 'seat-1',
    status: const OrderStatusPending(),
    totalAmount: 10000,
    orderedAt: DateTime(2024),
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  final deliveredOrder = pendingOrder.copyWith(
    status: const OrderStatusDelivered(),
    deliveredAt: DateTime(2024),
  );

  setUp(() {
    mockOrderRepo = MockIOrderRepository();
    sut = DeliverOrderUseCase(orderRepository: mockOrderRepo);
  });

  group('DeliverOrderUseCase', () {
    test('PENDING 주문을 DELIVERED로 전환한다', () async {
      when(mockOrderRepo.deliver('order-1')).thenAnswer((_) async => deliveredOrder);

      final result = await sut.execute('order-1');

      expect(result.status, isA<OrderStatusDelivered>());
      expect(result.deliveredAt, isNotNull);
      verify(mockOrderRepo.deliver('order-1')).called(1);
    });

    test('잘못된 상태 전이 시 InvalidStateTransitionException을 전파한다', () async {
      when(mockOrderRepo.deliver('order-1')).thenThrow(
        const InvalidStateTransitionException(from: 'cancelled', to: 'delivered'),
      );

      await expectLater(
        sut.execute('order-1'),
        throwsA(isA<InvalidStateTransitionException>()),
      );
      verify(mockOrderRepo.deliver('order-1')).called(1);
    });
  });
}
