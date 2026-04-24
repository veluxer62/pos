import 'package:pos/domain/entities/order.dart';
import 'package:pos/domain/value_objects/order_status.dart';

class OrderItemInput {
  OrderItemInput({
    required this.menuItemId,
    required this.quantity,
  }) {
    if (quantity < 1) {
      throw ArgumentError.value(quantity, 'quantity', 'must be >= 1');
    }
  }

  final String menuItemId;
  final int quantity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderItemInput &&
          menuItemId == other.menuItemId &&
          quantity == other.quantity;

  @override
  int get hashCode => Object.hash(menuItemId, quantity);
}

abstract interface class IOrderRepository {
  /// OPEN 영업일 없으면 [BusinessDayNotFoundException].
  /// [items]에 동일 menuItemId가 중복될 경우 구현체가 합산 또는 오류 처리.
  Future<Order> create({
    required String businessDayId,
    required String seatId,
    required List<OrderItemInput> items,
  });
  Future<Order?> findById(String id);
  Future<List<Order>> findByBusinessDay(
    String businessDayId, {
    OrderStatus? status,
  });

  /// 좌석의 활성 주문(PENDING/DELIVERED). 없으면 null.
  Future<Order?> findActiveOrderBySeat(String seatId);

  /// PENDING → DELIVERED. 그 외면 [InvalidStateTransitionException].
  Future<Order> deliver(String orderId);

  /// DELIVERED → PAID. 그 외면 [InvalidStateTransitionException].
  Future<Order> payImmediate(String orderId);

  /// DELIVERED → CREDITED. 그 외면 [InvalidStateTransitionException].
  Future<Order> payCredit(String orderId, String creditAccountId);

  /// PENDING 또는 DELIVERED → CANCELLED. 그 외면 [InvalidStateTransitionException].
  Future<Order> cancel(String orderId);

  /// PAID → REFUNDED. 그 외면 [InvalidStateTransitionException].
  Future<Order> refund(String orderId);

  /// DELIVERED 이후면 [OrderNotModifiableException].
  Future<Order> addItem(String orderId, OrderItemInput item);

  /// quantity=0이면 항목 삭제. itemId 없으면 [OrderItemNotFoundException].
  Future<Order> updateItemQuantity(String orderId, String itemId, int quantity);
  Stream<List<Order>> watchByBusinessDay(String businessDayId);
}
