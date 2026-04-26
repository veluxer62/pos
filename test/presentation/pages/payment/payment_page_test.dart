import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/di/providers.dart';
import 'package:pos/domain/entities/order.dart';
import 'package:pos/domain/repositories/i_order_repository.dart';
import 'package:pos/domain/value_objects/order_status.dart';
import 'package:pos/presentation/pages/payment/payment_page.dart';

class _StubOrderRepository implements IOrderRepository {
  _StubOrderRepository(this._order);

  final Order _order;

  @override
  Future<Order?> findById(String id) async => _order;

  @override
  Future<Order?> findActiveOrderBySeat(String seatId) async => null;

  @override
  Future<Order> create({
    required String businessDayId,
    required String seatId,
    required List<OrderItemInput> items,
  }) => throw UnimplementedError();

  @override
  Future<List<Order>> findByBusinessDay(String businessDayId, {OrderStatus? status}) =>
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
  Future<Order> updateItemQuantity(String orderId, String itemId, int quantity) =>
      throw UnimplementedError();

  @override
  Stream<List<Order>> watchByBusinessDay(String businessDayId) =>
      throw UnimplementedError();
}

Widget buildPaymentPage(Order order) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => ProviderScope(
          overrides: [
            orderRepositoryProvider.overrideWithValue(_StubOrderRepository(order)),
          ],
          child: PaymentPage(orderId: order.id),
        ),
      ),
    ],
  );

  return MaterialApp.router(routerConfig: router);
}

void main() {
  final now = DateTime(2024);

  Order makeOrder(OrderStatus status) => Order(
        id: 'order-1',
        businessDayId: 'bd-1',
        seatId: 'seat-1',
        status: status,
        totalAmount: 25000,
        orderedAt: now,
        createdAt: now,
        updatedAt: now,
      );

  group('PaymentPage', () {
    testWidgets('결제 금액을 표시한다', (tester) async {
      await tester.pumpWidget(buildPaymentPage(makeOrder(const OrderStatusDelivered())));
      await tester.pump();

      expect(find.text('25,000원'), findsOneWidget);
    });

    testWidgets('DELIVERED 상태이면 즉시 결제·외상 결제 버튼이 활성화된다', (tester) async {
      await tester.pumpWidget(buildPaymentPage(makeOrder(const OrderStatusDelivered())));
      await tester.pump();

      expect(find.text('즉시 결제'), findsOneWidget);
      expect(find.text('외상 결제'), findsOneWidget);
    });

    testWidgets('PENDING 상태이면 결제 버튼이 비활성화된다', (tester) async {
      await tester.pumpWidget(buildPaymentPage(makeOrder(const OrderStatusPending())));
      await tester.pump();

      final immediateButton = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text('즉시 결제'),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(immediateButton.onPressed, isNull);
    });

    testWidgets('DELIVERED 아닌 상태이면 안내 문구를 표시한다', (tester) async {
      await tester.pumpWidget(buildPaymentPage(makeOrder(const OrderStatusPending())));
      await tester.pump();

      expect(find.text('전달 완료 상태인 주문만 결제할 수 있습니다.'), findsOneWidget);
    });
  });
}
