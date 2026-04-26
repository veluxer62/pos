import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/di/providers.dart';
import 'package:pos/core/router/router.dart';
import 'package:pos/domain/entities/order.dart';
import 'package:pos/domain/entities/seat.dart';
import 'package:pos/domain/repositories/i_order_repository.dart';
import 'package:pos/domain/repositories/i_seat_repository.dart';
import 'package:pos/domain/value_objects/order_status.dart';

void main() {
  group('AppRoutes', () {
    test('order 경로는 루트이다', () {
      expect(AppRoutes.order, '/');
    });

    test('모든 경로가 /로 시작한다', () {
      expect(AppRoutes.credit, startsWith('/'));
      expect(AppRoutes.report, startsWith('/'));
      expect(AppRoutes.settings, startsWith('/'));
      expect(AppRoutes.businessDay, startsWith('/'));
    });

    test('각 경로가 고유하다', () {
      final routes = [
        AppRoutes.order,
        AppRoutes.credit,
        AppRoutes.report,
        AppRoutes.settings,
        AppRoutes.businessDay,
      ];
      expect(routes.toSet().length, routes.length);
    });
  });

  group('AppRouter', () {
    Widget buildTestApp(GoRouter router) => ProviderScope(
          overrides: [
            seatRepositoryProvider.overrideWith((_) => _StubSeatRepository()),
            orderRepositoryProvider.overrideWith((_) => _StubOrderRepository()),
          ],
          child: MaterialApp.router(routerConfig: router),
        );

    testWidgets('businessDayGuard가 null이면 정상 라우팅된다', (tester) async {
      final appRouter = AppRouter();

      await tester.pumpWidget(buildTestApp(appRouter.router));
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('businessDayGuard가 제공되면 redirect에 호출된다', (tester) async {
      var guardCalled = false;
      final appRouter = AppRouter(
        businessDayGuard: (context, state) {
          guardCalled = true;
          return null;
        },
      );

      await tester.pumpWidget(buildTestApp(appRouter.router));
      await tester.pumpAndSettle();

      expect(guardCalled, isTrue);
    });

    testWidgets('businessDay 경로로 리다이렉트 시 무한 루프 없이 이동한다',
        (tester) async {
      final appRouter = AppRouter(
        businessDayGuard: (context, state) => AppRoutes.businessDay,
      );

      await tester.pumpWidget(buildTestApp(appRouter.router));
      await tester.pumpAndSettle();

      expect(
        appRouter.router.routerDelegate.currentConfiguration.uri.path,
        AppRoutes.businessDay,
      );
    });
  });
}

class _StubSeatRepository implements ISeatRepository {
  @override
  Future<List<Seat>> findAll() async => [];

  @override
  Future<Seat?> findById(String id) async => null;

  @override
  Future<Seat?> findBySeatNumber(String seatNumber) async => null;

  @override
  Future<Seat> create({required String seatNumber, required int capacity}) =>
      throw UnimplementedError();

  @override
  Future<Seat> update(String id, {String? seatNumber, int? capacity}) =>
      throw UnimplementedError();

  @override
  Future<void> delete(String id) => throw UnimplementedError();

  @override
  Stream<List<Seat>> watchAll() => const Stream.empty();
}

class _StubOrderRepository implements IOrderRepository {
  @override
  Future<Order?> findActiveOrderBySeat(String seatId) async => null;

  @override
  Future<Order> create({
    required String businessDayId,
    required String seatId,
    required List<OrderItemInput> items,
  }) => throw UnimplementedError();

  @override
  Future<Order?> findById(String id) async => null;

  @override
  Future<List<Order>> findByBusinessDay(
    String businessDayId, {
    OrderStatus? status,
  }) async => [];

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
  Future<Order> updateItemQuantity(
    String orderId,
    String itemId,
    int quantity,
  ) => throw UnimplementedError();

  @override
  Stream<List<Order>> watchByBusinessDay(String businessDayId) =>
      const Stream.empty();
}
