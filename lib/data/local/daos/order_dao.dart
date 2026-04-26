import 'package:drift/drift.dart';
import 'package:pos/data/local/database/app_database.dart';
import 'package:pos/data/local/database/tables.dart';
import 'package:pos/domain/entities/order.dart';
import 'package:pos/domain/entities/order_item.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';
import 'package:pos/domain/repositories/i_order_repository.dart';
import 'package:pos/domain/value_objects/order_status.dart';
import 'package:uuid/uuid.dart';

part 'order_dao.g.dart';

@DriftAccessor(tables: [Orders, OrderItems, MenuItems])
class OrderDao extends DatabaseAccessor<AppDatabase> with _$OrderDaoMixin {
  OrderDao(super.db);

  final _uuid = const Uuid();

  Future<Order> create({
    required String businessDayId,
    required String seatId,
    required List<OrderItemInput> items,
  }) async {
    return db.transaction(() async {
      final now = DateTime.now();
      final orderId = _uuid.v4();

      var totalAmount = 0;
      final itemCompanions = <OrderItemsCompanion>[];

      for (final item in items) {
        final menuRow = await (select(menuItems)
              ..where((t) => t.id.equals(item.menuItemId)))
            .getSingleOrNull();
        if (menuRow == null) throw MenuItemNotFoundException(item.menuItemId);

        final subtotal = menuRow.price * item.quantity;
        totalAmount += subtotal;

        itemCompanions.add(
          OrderItemsCompanion.insert(
            id: _uuid.v4(),
            orderId: orderId,
            menuItemId: item.menuItemId,
            menuName: menuRow.name,
            unitPrice: menuRow.price,
            quantity: item.quantity,
            subtotal: subtotal,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      await into(orders).insert(
        OrdersCompanion.insert(
          id: orderId,
          businessDayId: businessDayId,
          seatId: seatId,
          status: const OrderStatusPending(),
          totalAmount: totalAmount,
          orderedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      );

      for (final companion in itemCompanions) {
        await into(orderItems).insert(companion);
      }

      return _fetchOrder(orderId);
    });
  }

  Future<Order?> findById(String id) async {
    final row = await (select(orders)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _rowToEntity(row);
  }

  Future<List<Order>> findByBusinessDay(
    String businessDayId, {
    OrderStatus? status,
  }) async {
    final query = select(orders)
      ..where((t) => t.businessDayId.equals(businessDayId))
      ..orderBy([(t) => OrderingTerm.desc(t.orderedAt)]);

    if (status != null) {
      query.where((t) => t.status.equals(status.name));
    }

    final rows = await query.get();
    return rows.map(_rowToEntity).toList();
  }

  Future<Order?> findActiveOrderBySeat(String seatId) async {
    final row = await (select(orders)
          ..where(
            (t) =>
                t.seatId.equals(seatId) &
                (t.status.equals(OrderStatusPending.statusName) |
                    t.status.equals(OrderStatusDelivered.statusName)),
          ))
        .getSingleOrNull();
    return row == null ? null : _rowToEntity(row);
  }

  Future<Order> deliver(String orderId) async {
    final row = await (select(orders)..where((t) => t.id.equals(orderId)))
        .getSingleOrNull();
    if (row == null) throw OrderNotFoundException(orderId);

    if (row.status is! OrderStatusPending) {
      throw InvalidStateTransitionException(
        from: row.status.name,
        to: OrderStatusDelivered.statusName,
      );
    }

    final now = DateTime.now();
    await (update(orders)..where((t) => t.id.equals(orderId))).write(
      OrdersCompanion(
        status: const Value(OrderStatusDelivered()),
        deliveredAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    return _fetchOrder(orderId);
  }

  Future<Order> cancel(String orderId) async {
    final row = await (select(orders)..where((t) => t.id.equals(orderId)))
        .getSingleOrNull();
    if (row == null) throw OrderNotFoundException(orderId);

    if (row.status is! OrderStatusPending && row.status is! OrderStatusDelivered) {
      throw InvalidStateTransitionException(
        from: row.status.name,
        to: OrderStatusCancelled.statusName,
      );
    }

    final now = DateTime.now();
    await (update(orders)..where((t) => t.id.equals(orderId))).write(
      OrdersCompanion(
        status: const Value(OrderStatusCancelled()),
        cancelledAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    return _fetchOrder(orderId);
  }

  Stream<List<Order>> watchByBusinessDay(String businessDayId) {
    return (select(orders)
          ..where((t) => t.businessDayId.equals(businessDayId))
          ..orderBy([(t) => OrderingTerm.desc(t.orderedAt)]))
        .watch()
        .map((rows) => rows.map(_rowToEntity).toList());
  }

  Future<List<OrderItem>> findItemsByOrder(String orderId) async {
    final rows = await (select(orderItems)
          ..where((t) => t.orderId.equals(orderId)))
        .get();
    return rows.map(_itemRowToEntity).toList();
  }

  Future<Order> _fetchOrder(String orderId) async {
    final row = await (select(orders)..where((t) => t.id.equals(orderId)))
        .getSingle();
    return _rowToEntity(row);
  }

  Order _rowToEntity(OrderRow row) => Order(
        id: row.id,
        businessDayId: row.businessDayId,
        seatId: row.seatId,
        status: row.status,
        totalAmount: row.totalAmount,
        orderedAt: row.orderedAt,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        paymentType: row.paymentType,
        creditAccountId: row.creditAccountId,
        deliveredAt: row.deliveredAt,
        paidAt: row.paidAt,
        creditedAt: row.creditedAt,
        cancelledAt: row.cancelledAt,
        refundedAt: row.refundedAt,
      );

  OrderItem _itemRowToEntity(OrderItemRow row) => OrderItem(
        id: row.id,
        orderId: row.orderId,
        menuItemId: row.menuItemId,
        menuName: row.menuName,
        unitPrice: row.unitPrice,
        quantity: row.quantity,
        subtotal: row.subtotal,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );
}
