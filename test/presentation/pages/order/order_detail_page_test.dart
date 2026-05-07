import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/di/providers.dart';
import 'package:pos/domain/entities/order.dart';
import 'package:pos/domain/entities/order_item.dart';
import 'package:pos/domain/repositories/i_order_repository.dart';
import 'package:pos/domain/value_objects/order_status.dart';
import 'package:pos/presentation/pages/order/order_detail_page.dart';

final _now = DateTime(2024, 1, 1, 9);

final _pendingOrder = Order(
  id: 'order-1',
  businessDayId: 'bd-1',
  seatId: 'seat-1',
  status: const OrderStatusPending(),
  totalAmount: 18000,
  orderedAt: _now,
  createdAt: _now,
  updatedAt: _now,
);

final _orderItems = [
  OrderItem(
    id: 'item-1',
    orderId: 'order-1',
    menuItemId: 'menu-1',
    menuName: '김치찌개',
    unitPrice: 9000,
    quantity: 2,
    subtotal: 18000,
    createdAt: _now,
    updatedAt: _now,
  ),
];

class _StubOrderRepository implements IOrderRepository {
  _StubOrderRepository({
    required this.order,
    required this.items,
  });

  final Order order;
  final List<OrderItem> items;

  @override
  Future<Order?> findById(String id) async => order;

  @override
  Future<Order?> findActiveOrderBySeat(String seatId) async => null;

  @override
  Future<Order> create({
    required String businessDayId,
    required String seatId,
    required List<OrderItemInput> items,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<Order>> findByBusinessDay(
    String businessDayId, {
    OrderStatus? status,
  }) =>
      throw UnimplementedError();

  @override
  Future<Order> deliver(String orderId) => throw UnimplementedError();

  @override
  Future<Order> payImmediate(String orderId) => throw UnimplementedError();

  @override
  Future<Order> payCredit(String orderId, String creditAccountId) =>
      throw UnimplementedError();

  @override
  Future<Order> cancel(String orderId) => throw UnimplementedError();

  @override
  Future<Order> refund(String orderId) => throw UnimplementedError();

  @override
  Future<Order> addItem(String orderId, OrderItemInput item) =>
      throw UnimplementedError();

  @override
  Future<Order> removeItem(String orderId, String orderItemId) =>
      throw UnimplementedError();

  @override
  Future<Order> updateItemQuantity(
    String orderId,
    String itemId,
    int quantity,
  ) =>
      throw UnimplementedError();

  @override
  Stream<List<Order>> watchByBusinessDay(String businessDayId) =>
      const Stream.empty();

  @override
  Stream<List<OrderItem>> watchItemsByOrder(String orderId) =>
      Stream.value(items);
}

Widget buildPage({
  required Order order,
  required List<OrderItem> items,
}) =>
    ProviderScope(
      overrides: [
        orderRepositoryProvider.overrideWithValue(
          _StubOrderRepository(order: order, items: items),
        ),
      ],
      child: MaterialApp(
        home: OrderDetailPage(orderId: order.id),
      ),
    );

void main() {
  group('OrderDetailPage', () {
    testWidgets('주문 항목이 있으면 메뉴명을 표시한다', (tester) async {
      await tester.pumpWidget(
        buildPage(order: _pendingOrder, items: _orderItems),
      );
      await tester.pumpAndSettle();

      expect(find.text('김치찌개'), findsOneWidget);
    });

    testWidgets('빈 항목 주문 시 주문 항목 없음 텍스트를 표시한다', (tester) async {
      await tester.pumpWidget(
        buildPage(order: _pendingOrder, items: const []),
      );
      await tester.pumpAndSettle();

      expect(find.text('주문 항목 없음'), findsOneWidget);
    });

    testWidgets('주문 수량과 소계를 표시한다', (tester) async {
      await tester.pumpWidget(
        buildPage(order: _pendingOrder, items: _orderItems),
      );
      await tester.pumpAndSettle();

      expect(find.text('×2'), findsOneWidget);
      expect(find.text('18,000원'), findsOneWidget);
    });

    testWidgets('PENDING 주문이면 전달 완료 버튼이 표시된다', (tester) async {
      await tester.pumpWidget(
        buildPage(order: _pendingOrder, items: _orderItems),
      );
      await tester.pumpAndSettle();

      expect(find.text('전달 완료'), findsOneWidget);
    });
  });
}
