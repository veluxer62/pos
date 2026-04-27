import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/di/providers.dart';
import 'package:pos/domain/entities/order.dart';
import 'package:pos/domain/entities/seat.dart';
import 'package:pos/domain/repositories/i_order_repository.dart';
import 'package:pos/domain/repositories/i_seat_repository.dart';
import 'package:pos/domain/value_objects/order_status.dart';
import 'package:pos/main.dart';

void main() {
  testWidgets('PosApp smoke test — app renders without crash', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seatRepositoryProvider.overrideWith((_) => _StubSeatRepository()),
          orderRepositoryProvider.overrideWith((_) => _StubOrderRepository()),
        ],
        child: const PosApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PosApp), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
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
  }) =>
      throw UnimplementedError();

  @override
  Future<Order?> findById(String id) async => null;

  @override
  Future<List<Order>> findByBusinessDay(
    String businessDayId, {
    OrderStatus? status,
  }) async =>
      [];

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
  ) =>
      throw UnimplementedError();

  @override
  Stream<List<Order>> watchByBusinessDay(String businessDayId) =>
      const Stream.empty();
}
