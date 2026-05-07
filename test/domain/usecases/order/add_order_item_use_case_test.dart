import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pos/domain/entities/menu_item.dart';
import 'package:pos/domain/entities/order.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';
import 'package:pos/domain/repositories/i_menu_item_repository.dart';
import 'package:pos/domain/repositories/i_order_repository.dart';
import 'package:pos/domain/usecases/order/add_order_item_use_case.dart';
import 'package:pos/domain/value_objects/order_status.dart';

import 'add_order_item_use_case_test.mocks.dart';

@GenerateMocks([IOrderRepository, IMenuItemRepository])
void main() {
  late MockIOrderRepository mockOrderRepo;
  late MockIMenuItemRepository mockMenuItemRepo;
  late AddOrderItemUseCase sut;

  final pendingOrder = Order(
    id: 'order-1',
    businessDayId: 'bd-1',
    seatId: 'seat-1',
    status: const OrderStatusPending(),
    totalAmount: 4500,
    orderedAt: DateTime(2024),
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  final deliveredOrder = pendingOrder.copyWith(
    status: const OrderStatusDelivered(),
  );

  final availableMenu = MenuItem(
    id: 'menu-1',
    name: '아메리카노',
    price: 4500,
    category: '음료',
    isAvailable: true,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  final unavailableMenu = availableMenu.copyWith(isAvailable: false);

  final updatedOrder = pendingOrder.copyWith(totalAmount: 9000);

  setUp(() {
    mockOrderRepo = MockIOrderRepository();
    mockMenuItemRepo = MockIMenuItemRepository();
    sut = AddOrderItemUseCase(
      orderRepository: mockOrderRepo,
      menuItemRepository: mockMenuItemRepo,
    );
  });

  group('AddOrderItemUseCase', () {
    test('PENDING 주문에 항목을 추가한다', () async {
      when(mockOrderRepo.findById('order-1'))
          .thenAnswer((_) async => pendingOrder);
      when(mockMenuItemRepo.findById('menu-1'))
          .thenAnswer((_) async => availableMenu);
      when(
        mockOrderRepo.addItem(
          'order-1',
          argThat(
            predicate<OrderItemInput>(
              (i) => i.menuItemId == 'menu-1' && i.quantity == 2,
            ),
          ),
        ),
      ).thenAnswer((_) async => updatedOrder);

      final result = await sut.execute(
        orderId: 'order-1',
        menuItemId: 'menu-1',
        quantity: 2,
      );

      expect(result, updatedOrder);
      verify(
        mockOrderRepo.addItem(
          'order-1',
          argThat(
            predicate<OrderItemInput>(
              (i) => i.menuItemId == 'menu-1' && i.quantity == 2,
            ),
          ),
        ),
      ).called(1);
    });

    test('DELIVERED 주문에 항목 추가 시 OrderNotEditableException을 던진다', () async {
      when(mockOrderRepo.findById('order-1'))
          .thenAnswer((_) async => deliveredOrder);

      await expectLater(
        sut.execute(orderId: 'order-1', menuItemId: 'menu-1', quantity: 1),
        throwsA(isA<OrderNotEditableException>()),
      );
      verifyNever(mockMenuItemRepo.findById(any));
      verifyNever(mockOrderRepo.addItem(any, any));
    });

    test('품절 메뉴 추가 시 MenuNotAvailableException을 던진다', () async {
      when(mockOrderRepo.findById('order-1'))
          .thenAnswer((_) async => pendingOrder);
      when(mockMenuItemRepo.findById('menu-1'))
          .thenAnswer((_) async => unavailableMenu);

      await expectLater(
        sut.execute(orderId: 'order-1', menuItemId: 'menu-1', quantity: 1),
        throwsA(isA<MenuNotAvailableException>()),
      );
      verifyNever(mockOrderRepo.addItem(any, any));
    });

    test('quantity < 1 이면 ArgumentError를 던진다', () async {
      await expectLater(
        sut.execute(orderId: 'order-1', menuItemId: 'menu-1', quantity: 0),
        throwsA(isA<ArgumentError>()),
      );
      verifyNever(mockOrderRepo.findById(any));
    });
  });
}
