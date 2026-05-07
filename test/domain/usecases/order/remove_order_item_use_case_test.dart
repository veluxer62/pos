import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pos/domain/entities/order.dart';
import 'package:pos/domain/entities/order_item.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';
import 'package:pos/domain/repositories/i_order_repository.dart';
import 'package:pos/domain/usecases/order/remove_order_item_use_case.dart';
import 'package:pos/domain/value_objects/order_status.dart';

import 'remove_order_item_use_case_test.mocks.dart';

@GenerateMocks([IOrderRepository])
void main() {
  late MockIOrderRepository mockOrderRepo;
  late RemoveOrderItemUseCase sut;

  OrderItem makeItem(String id) => OrderItem(
        id: id,
        orderId: 'order-1',
        menuItemId: 'menu-1',
        menuName: '아메리카노',
        unitPrice: 4500,
        quantity: 1,
        subtotal: 4500,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

  final item1 = makeItem('item-1');
  final item2 = makeItem('item-2');

  final pendingOrderWithTwoItems = Order(
    id: 'order-1',
    businessDayId: 'bd-1',
    seatId: 'seat-1',
    status: const OrderStatusPending(),
    totalAmount: 9000,
    orderedAt: DateTime(2024),
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  final pendingOrderWithOneItem = pendingOrderWithTwoItems.copyWith(
    totalAmount: 4500,
  );

  final deliveredOrder = pendingOrderWithTwoItems.copyWith(
    status: const OrderStatusDelivered(),
  );

  setUp(() {
    mockOrderRepo = MockIOrderRepository();
    sut = RemoveOrderItemUseCase(orderRepository: mockOrderRepo);
  });

  group('RemoveOrderItemUseCase', () {
    test('PENDING 주문에서 항목(2개 중 1개)을 삭제한다', () async {
      when(mockOrderRepo.findById('order-1'))
          .thenAnswer((_) async => pendingOrderWithTwoItems);
      when(mockOrderRepo.watchItemsByOrder('order-1'))
          .thenAnswer((_) => Stream.value([item1, item2]));
      when(mockOrderRepo.removeItem('order-1', 'item-1'))
          .thenAnswer((_) async => pendingOrderWithOneItem);

      final result = await sut.execute(
        orderId: 'order-1',
        orderItemId: 'item-1',
      );

      expect(result, pendingOrderWithOneItem);
      verify(mockOrderRepo.removeItem('order-1', 'item-1')).called(1);
    });

    test('마지막 항목 삭제 시 MinimumOrderItemException을 던진다', () async {
      when(mockOrderRepo.findById('order-1'))
          .thenAnswer((_) async => pendingOrderWithOneItem);
      when(mockOrderRepo.watchItemsByOrder('order-1'))
          .thenAnswer((_) => Stream.value([item1]));

      await expectLater(
        sut.execute(orderId: 'order-1', orderItemId: 'item-1'),
        throwsA(isA<MinimumOrderItemException>()),
      );
      verifyNever(mockOrderRepo.removeItem(any, any));
    });

    test('DELIVERED 주문에서 삭제 시 OrderNotEditableException을 던진다', () async {
      when(mockOrderRepo.findById('order-1'))
          .thenAnswer((_) async => deliveredOrder);
      when(mockOrderRepo.watchItemsByOrder('order-1'))
          .thenAnswer((_) => Stream.value([item1, item2]));

      await expectLater(
        sut.execute(orderId: 'order-1', orderItemId: 'item-1'),
        throwsA(isA<OrderNotEditableException>()),
      );
      verifyNever(mockOrderRepo.removeItem(any, any));
    });
  });
}
