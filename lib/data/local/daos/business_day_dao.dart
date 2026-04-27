import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:pos/data/local/database/app_database.dart';
import 'package:pos/data/local/database/tables.dart';
import 'package:pos/domain/entities/business_day.dart';
import 'package:pos/domain/entities/daily_sales_report.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';
import 'package:pos/domain/value_objects/business_day_status.dart';
import 'package:pos/domain/value_objects/close_result.dart';
import 'package:pos/domain/value_objects/order_status.dart';
import 'package:uuid/uuid.dart';

part 'business_day_dao.g.dart';

@DriftAccessor(tables: [BusinessDays, Orders, OrderItems, DailySalesReports])
class BusinessDayDao extends DatabaseAccessor<AppDatabase>
    with _$BusinessDayDaoMixin {
  BusinessDayDao(super.db);

  Future<BusinessDay?> getOpen() async {
    final row = await (select(businessDays)
          ..where((t) => t.status.equals(BusinessDayStatus.open.name))
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  Future<BusinessDay?> findById(String id) async {
    final row = await (select(businessDays)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  Future<BusinessDay> open() async {
    final existing = await getOpen();
    if (existing != null) throw const BusinessDayAlreadyOpenException();

    final id = const Uuid().v4();
    final now = DateTime.now();
    return insert(
      BusinessDaysCompanion.insert(
        id: id,
        status: BusinessDayStatus.open,
        openedAt: now,
        createdAt: now,
      ),
    );
  }

  /// 영업 마감 + DailySalesReport 생성 — 원자적 트랜잭션.
  Future<CloseResult> closeBusinessDay({bool forceClose = false}) =>
      db.transaction(() async {
        final openDay = await getOpen();
        if (openDay == null) {
          throw const BusinessDayNotFoundException();
        }

        // 미처리 주문 조회
        final pendingRows = await (select(orders)
              ..where(
                (t) =>
                    t.businessDayId.equals(openDay.id) &
                    t.status.equals(const OrderStatusPending().name),
              ))
            .get();
        final deliveredRows = await (select(orders)
              ..where(
                (t) =>
                    t.businessDayId.equals(openDay.id) &
                    t.status.equals(const OrderStatusDelivered().name),
              ))
            .get();

        if (!forceClose &&
            (pendingRows.isNotEmpty || deliveredRows.isNotEmpty)) {
          throw PendingOrdersExistException(
            pendingCount: pendingRows.length,
            deliveredCount: deliveredRows.length,
          );
        }

        final now = DateTime.now();

        // forceClose: 미처리 주문을 CANCELLED로 변경
        final cancelledIds = [
          ...pendingRows.map((r) => r.id),
          ...deliveredRows.map((r) => r.id),
        ];
        for (final orderId in cancelledIds) {
          await (update(orders)..where((t) => t.id.equals(orderId))).write(
            OrdersCompanion(
              status: const Value(OrderStatusCancelled()),
              cancelledAt: Value(now),
              updatedAt: Value(now),
            ),
          );
        }

        // 집계
        final allOrders = await (select(orders)
              ..where((t) => t.businessDayId.equals(openDay.id)))
            .get();

        final paidOrders = allOrders
            .where((r) => r.status is OrderStatusPaid)
            .toList();
        final creditedOrders = allOrders
            .where((r) => r.status is OrderStatusCredited)
            .toList();
        final cancelledOrders = allOrders
            .where((r) => r.status is OrderStatusCancelled)
            .toList();
        final refundedOrders = allOrders
            .where((r) => r.status is OrderStatusRefunded)
            .toList();

        final totalRevenue =
            paidOrders.fold(0, (sum, r) => sum + r.totalAmount);
        final creditedAmount =
            creditedOrders.fold(0, (sum, r) => sum + r.totalAmount);
        final refundedAmount =
            refundedOrders.fold(0, (sum, r) => sum + r.totalAmount);
        final netRevenue = totalRevenue - refundedAmount;

        // 메뉴별 집계
        final menuSummary = await _buildMenuSummary(
          [...paidOrders, ...creditedOrders].map((r) => r.id).toList(),
        );

        // 시간대별 집계
        final hourlySummary = _buildHourlySummary([
          ...paidOrders,
          ...creditedOrders,
        ]);

        // 영업일 상태 업데이트
        await (update(businessDays)
              ..where((t) => t.id.equals(openDay.id)))
            .write(
          BusinessDaysCompanion(
            status: const Value(BusinessDayStatus.closed),
            closedAt: Value(now),
          ),
        );

        // 보고서 생성
        final reportId = const Uuid().v4();
        await into(dailySalesReports).insert(
          DailySalesReportsCompanion.insert(
            id: reportId,
            businessDayId: openDay.id,
            openedAt: openDay.openedAt,
            closedAt: now,
            totalRevenue: totalRevenue,
            paidOrderCount: paidOrders.length,
            creditedAmount: creditedAmount,
            creditedOrderCount: creditedOrders.length,
            cancelledOrderCount: cancelledOrders.length,
            refundedOrderCount: refundedOrders.length,
            refundedAmount: refundedAmount,
            netRevenue: netRevenue,
            menuSummaryJson: jsonEncode(menuSummary),
            hourlySummaryJson: jsonEncode(hourlySummary),
            createdAt: now,
          ),
        );

        final closedDay = (await findById(openDay.id))!;
        final report = (await getReport(openDay.id))!;

        return CloseResult(businessDay: closedDay, report: report);
      });

  Future<BusinessDay> insert(BusinessDaysCompanion companion) async {
    await into(businessDays).insert(companion);
    final row = await (select(businessDays)
          ..where((t) => t.id.equals(companion.id.value)))
        .getSingle();
    return _toEntity(row);
  }

  Future<BusinessDay> updateRow(
    String id,
    BusinessDaysCompanion companion,
  ) async {
    await (update(businessDays)..where((t) => t.id.equals(id))).write(companion);
    final row = await (select(businessDays)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    return _toEntity(row);
  }

  Stream<BusinessDay?> watchOpen() {
    return (select(businessDays)
          ..where((t) => t.status.equals(BusinessDayStatus.open.name)))
        .watchSingleOrNull()
        .map((row) => row == null ? null : _toEntity(row));
  }

  Future<List<BusinessDay>> findAll({
    DateTime? from,
    DateTime? to,
    int limit = 30,
    int offset = 0,
  }) async {
    final query = select(businessDays)
      ..orderBy([(t) => OrderingTerm.desc(t.openedAt)])
      ..limit(limit, offset: offset);

    if (from != null) {
      query.where((t) => t.openedAt.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      query.where((t) => t.openedAt.isSmallerOrEqualValue(to));
    }

    final rows = await query.get();
    return rows.map(_toEntity).toList();
  }

  Future<DailySalesReport?> getReport(String businessDayId) async {
    final row = await (select(dailySalesReports)
          ..where((t) => t.businessDayId.equals(businessDayId)))
        .getSingleOrNull();
    return row == null ? null : _toReport(row);
  }

  Future<List<DailySalesReport>> getReports({
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await (select(dailySalesReports)
          ..where(
            (t) =>
                t.openedAt.isBiggerOrEqualValue(from) &
                t.openedAt.isSmallerOrEqualValue(to),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.openedAt)]))
        .get();
    return rows.map(_toReport).toList();
  }

  Future<List<Map<String, dynamic>>> _buildMenuSummary(
    List<String> orderIds,
  ) async {
    if (orderIds.isEmpty) return [];

    final items = await (select(orderItems)
          ..where((t) => t.orderId.isIn(orderIds)))
        .get();

    final grouped = <String, Map<String, dynamic>>{};
    for (final item in items) {
      final key = item.menuItemId;
      if (grouped.containsKey(key)) {
        grouped[key]!['quantity'] =
            (grouped[key]!['quantity'] as int) + item.quantity;
        grouped[key]!['totalAmount'] =
            (grouped[key]!['totalAmount'] as int) + item.subtotal;
      } else {
        grouped[key] = {
          'menuItemId': item.menuItemId,
          'menuName': item.menuName,
          'quantity': item.quantity,
          'totalAmount': item.subtotal,
        };
      }
    }

    final sorted = grouped.values.toList()
      ..sort(
        (a, b) =>
            (b['quantity'] as int).compareTo(a['quantity'] as int),
      );
    return sorted;
  }

  List<Map<String, dynamic>> _buildHourlySummary(List<OrderRow> paidOrders) {
    final hourly = <int, Map<String, dynamic>>{};
    for (final order in paidOrders) {
      final hour = order.orderedAt.hour;
      if (hourly.containsKey(hour)) {
        hourly[hour]!['orderCount'] =
            (hourly[hour]!['orderCount'] as int) + 1;
        hourly[hour]!['totalAmount'] =
            (hourly[hour]!['totalAmount'] as int) + order.totalAmount;
      } else {
        hourly[hour] = {
          'hour': hour,
          'orderCount': 1,
          'totalAmount': order.totalAmount,
        };
      }
    }

    return List.generate(24, (h) {
      return hourly[h] ?? {'hour': h, 'orderCount': 0, 'totalAmount': 0};
    });
  }

  BusinessDay _toEntity(BusinessDayRow row) => BusinessDay(
        id: row.id,
        status: row.status,
        openedAt: row.openedAt,
        createdAt: row.createdAt,
        closedAt: row.closedAt,
      );

  DailySalesReport _toReport(DailySalesReportRow row) => DailySalesReport(
        id: row.id,
        businessDayId: row.businessDayId,
        openedAt: row.openedAt,
        closedAt: row.closedAt,
        totalRevenue: row.totalRevenue,
        paidOrderCount: row.paidOrderCount,
        creditedAmount: row.creditedAmount,
        creditedOrderCount: row.creditedOrderCount,
        cancelledOrderCount: row.cancelledOrderCount,
        refundedOrderCount: row.refundedOrderCount,
        refundedAmount: row.refundedAmount,
        netRevenue: row.netRevenue,
        menuSummaryJson: row.menuSummaryJson,
        hourlySummaryJson: row.hourlySummaryJson,
        createdAt: row.createdAt,
      );
}
