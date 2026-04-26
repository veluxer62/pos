import 'package:pos/data/local/daos/order_dao.dart';
import 'package:pos/domain/entities/order.dart';
import 'package:pos/domain/repositories/i_order_repository.dart';
import 'package:pos/domain/value_objects/order_status.dart';

class LocalOrderRepository implements IOrderRepository {
  LocalOrderRepository(this._dao);

  final OrderDao _dao;

  @override
  Future<Order> create({
    required String businessDayId,
    required String seatId,
    required List<OrderItemInput> items,
  }) =>
      _dao.create(businessDayId: businessDayId, seatId: seatId, items: items);

  @override
  Future<Order?> findById(String id) => _dao.findById(id);

  @override
  Future<List<Order>> findByBusinessDay(
    String businessDayId, {
    OrderStatus? status,
  }) =>
      _dao.findByBusinessDay(businessDayId, status: status);

  @override
  Future<Order?> findActiveOrderBySeat(String seatId) =>
      _dao.findActiveOrderBySeat(seatId);

  @override
  Future<Order> deliver(String orderId) => _dao.deliver(orderId);

  @override
  Future<Order> cancel(String orderId) => _dao.cancel(orderId);

  @override
  Future<Order> payImmediate(String orderId) {
    // Phase 4에서 구현
    throw UnimplementedError('Phase 4에서 구현');
  }

  @override
  Future<Order> payCredit(String orderId, String creditAccountId) {
    // Phase 4에서 구현
    throw UnimplementedError('Phase 4에서 구현');
  }

  @override
  Future<Order> refund(String orderId) {
    // Phase 4에서 구현
    throw UnimplementedError('Phase 4에서 구현');
  }

  @override
  Future<Order> addItem(String orderId, OrderItemInput item) {
    // Phase 3 후반 태스크에서 구현
    throw UnimplementedError('추후 구현');
  }

  @override
  Future<Order> updateItemQuantity(
    String orderId,
    String itemId,
    int quantity,
  ) {
    // Phase 3 후반 태스크에서 구현
    throw UnimplementedError('추후 구현');
  }

  @override
  Stream<List<Order>> watchByBusinessDay(String businessDayId) =>
      _dao.watchByBusinessDay(businessDayId);
}
