import 'package:flutter_test/flutter_test.dart';
import 'package:pos/domain/entities/daily_sales_report.dart';

void main() {
  final base = DailySalesReport(
    id: 'id-1',
    businessDayId: 'bd-1',
    openedAt: DateTime(2026, 4, 23, 9),
    closedAt: DateTime(2026, 4, 23, 22),
    totalRevenue: 500000,
    paidOrderCount: 30,
    creditedAmount: 50000,
    creditedOrderCount: 3,
    cancelledOrderCount: 2,
    refundedOrderCount: 1,
    refundedAmount: 9000,
    netRevenue: 491000,
    menuSummaryJson: '[]',
    hourlySummaryJson: '[]',
    createdAt: DateTime(2026, 4, 23, 22),
  );

  group('DailySalesReport copyWith', () {
    test('totalRevenue 변경', () {
      final updated = base.copyWith(totalRevenue: 600000);
      expect(updated.totalRevenue, equals(600000));
      expect(updated.businessDayId, equals(base.businessDayId));
    });

    test('인자 없이 호출하면 동일 값 유지', () {
      expect(base.copyWith().netRevenue, equals(base.netRevenue));
    });
  });

  group('DailySalesReport equality', () {
    test('동일 id이면 동등', () {
      expect(base, equals(base.copyWith(totalRevenue: 999999)));
    });

    test('다른 id이면 비동등', () {
      expect(base, isNot(equals(base.copyWith(id: 'id-2'))));
    });

    test('hashCode가 id 기반으로 일관됨', () {
      expect(
        base.hashCode,
        equals(base.copyWith(totalRevenue: 999999).hashCode),
      );
    });
  });
}
