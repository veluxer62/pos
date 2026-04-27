import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pos/domain/entities/order.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';
import 'package:pos/domain/repositories/i_order_repository.dart';
import 'package:pos/domain/usecases/order/pay_immediate_use_case.dart';
import 'package:pos/domain/value_objects/order_status.dart';

import 'pay_immediate_use_case_test.mocks.dart';

@GenerateMocks([IOrderRepository])
void main() {
  late MockIOrderRepository mockOrderRepo;
  late PayImmediateUseCase sut;

  final deliveredOrder = Order(
    id: 'order-1',
    businessDayId: 'bd-1',
    seatId: 'seat-1',
    status: const OrderStatusDelivered(),
    totalAmount: 10000,
    orderedAt: DateTime(2024),
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    deliveredAt: DateTime(2024),
  );

  final paidOrder = deliveredOrder.copyWith(
    status: const OrderStatusPaid(),
    paidAt: DateTime(2024),
  );

  setUp(() {
    mockOrderRepo = MockIOrderRepository();
    sut = PayImmediateUseCase(orderRepository: mockOrderRepo);
  });

  group('PayImmediateUseCase', () {
    test('DELIVERED 주문을 PAID로 전환한다', () async {
      when(mockOrderRepo.payImmediate('order-1'))
          .thenAnswer((_) async => paidOrder);

      final result = await sut.execute('order-1');

      expect(result.status, isA<OrderStatusPaid>());
      expect(result.paidAt, isNotNull);
      verify(mockOrderRepo.payImmediate('order-1')).called(1);
    });

    test('잘못된 상태 전이 시 InvalidStateTransitionException을 전파한다', () async {
      when(mockOrderRepo.payImmediate('order-1')).thenThrow(
        const InvalidStateTransitionException(from: 'pending', to: 'paid'),
      );

      await expectLater(
        sut.execute('order-1'),
        throwsA(isA<InvalidStateTransitionException>()),
      );
      verify(mockOrderRepo.payImmediate('order-1')).called(1);
    });
  });
}
