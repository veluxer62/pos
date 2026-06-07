import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos/data/local/services/sales_analysis_service.dart';
import 'package:pos/domain/entities/daily_sales_report.dart';
import 'package:pos/domain/entities/sales_analysis.dart';

void main() {
  late SalesAnalysisService sut;

  setUp(() {
    sut = SalesAnalysisService();
  });

  DailySalesReport makeReport({
    required String id,
    required DateTime closedAt,
    required int netRevenue,
    int totalRevenue = 0,
    int creditedAmount = 0,
    String menuJson = '[]',
    String hourlyJson = '[]',
  }) =>
      DailySalesReport(
        id: id,
        businessDayId: 'bd-$id',
        openedAt: closedAt,
        closedAt: closedAt,
        totalRevenue: totalRevenue == 0 ? netRevenue : totalRevenue,
        paidOrderCount: 1,
        creditedAmount: creditedAmount,
        creditedOrderCount: creditedAmount > 0 ? 1 : 0,
        cancelledOrderCount: 0,
        refundedOrderCount: 0,
        refundedAmount: 0,
        netRevenue: netRevenue,
        menuSummaryJson: menuJson,
        hourlySummaryJson: hourlyJson,
        createdAt: closedAt,
      );

  group('SalesAnalysisService', () {
    test('빈 리포트 목록이면 empty()를 반환한다', () {
      final result = sut.analyze([]);

      expect(result.reportCount, 0);
      expect(result.hasEnoughData, isFalse);
      expect(result.insights, isEmpty);
    });

    test('reportCount가 실제 리포트 개수와 일치한다', () {
      final reports = List.generate(
        5,
        (i) => makeReport(
          id: '$i',
          closedAt: DateTime(2024, 1, i + 1),
          netRevenue: 100000,
        ),
      );

      final result = sut.analyze(reports);

      expect(result.reportCount, 5);
    });

    test('요일별 평균 매출이 정확히 계산된다', () {
      // 월요일(1) 두 번: 100000, 200000 → 평균 150000
      final reports = [
        makeReport(
          id: '1',
          closedAt: DateTime(2024, 1, 1), // 월요일
          netRevenue: 100000,
        ),
        makeReport(
          id: '2',
          closedAt: DateTime(2024, 1, 8), // 월요일
          netRevenue: 200000,
        ),
      ];

      final result = sut.analyze(reports);

      expect(result.dayOfWeekAverages[DateTime.monday], 150000);
    });

    test('시간대별 평균 주문 수가 hourlySummaryJson에서 파싱된다', () {
      final hourlyJson = jsonEncode([
        {'hour': 12, 'orderCount': 4, 'totalAmount': 40000},
        {'hour': 18, 'orderCount': 6, 'totalAmount': 60000},
      ]);

      final reports = [
        makeReport(
          id: '1',
          closedAt: DateTime(2024, 1, 1),
          netRevenue: 100000,
          hourlyJson: hourlyJson,
        ),
      ];

      final result = sut.analyze(reports);

      expect(result.hourlyAverages[12], 4.0);
      expect(result.hourlyAverages[18], 6.0);
    });

    test('메뉴별 판매량이 합산되고 내림차순 정렬된다', () {
      final menuJson1 = jsonEncode([
        {'menuName': '비빔밥', 'quantity': 5, 'totalAmount': 50000},
        {'menuName': '된장찌개', 'quantity': 3, 'totalAmount': 24000},
      ]);
      final menuJson2 = jsonEncode([
        {'menuName': '비빔밥', 'quantity': 2, 'totalAmount': 20000},
        {'menuName': '순두부찌개', 'quantity': 4, 'totalAmount': 32000},
      ]);

      final reports = [
        makeReport(
          id: '1',
          closedAt: DateTime(2024, 1, 1),
          netRevenue: 74000,
          menuJson: menuJson1,
        ),
        makeReport(
          id: '2',
          closedAt: DateTime(2024, 1, 2),
          netRevenue: 52000,
          menuJson: menuJson2,
        ),
      ];

      final result = sut.analyze(reports);

      expect(result.topMenus.first.menuName, '비빔밥');
      expect(result.topMenus.first.totalQuantity, 7);
      expect(result.topMenus.length, lessThanOrEqualTo(5));
    });

    test('14일 이상 데이터에서 매출 상승 인사이트가 생성된다', () {
      final reports = [
        // 이전 주: 각 50000
        ...List.generate(
          7,
          (i) => makeReport(
            id: 'prev-$i',
            closedAt: DateTime(2024, 1, i + 1),
            netRevenue: 50000,
          ),
        ),
        // 이번 주: 각 100000 (100% 상승)
        ...List.generate(
          7,
          (i) => makeReport(
            id: 'curr-$i',
            closedAt: DateTime(2024, 1, i + 8),
            netRevenue: 100000,
          ),
        ),
      ];

      final result = sut.analyze(reports);

      expect(result.revenueTrend.direction, TrendDirection.up);
      expect(
        result.insights.any((i) => i.type == InsightType.positive),
        isTrue,
      );
    });

    test('외상 비율 30% 초과 시 경고 인사이트가 포함된다', () {
      final reports = List.generate(
        5,
        (i) => makeReport(
          id: '$i',
          closedAt: DateTime(2024, 1, i + 1),
          netRevenue: 70000,
          totalRevenue: 100000,
          creditedAmount: 40000, // 40% 외상
        ),
      );

      final result = sut.analyze(reports);

      expect(
        result.insights.any((i) => i.type == InsightType.warning),
        isTrue,
      );
    });

    test('7일 이동 평균이 최근 7개 리포트의 평균과 일치한다', () {
      final revenues = [100000, 120000, 80000, 110000, 90000, 130000, 100000];
      final expected =
          revenues.reduce((a, b) => a + b) ~/ revenues.length;

      final reports = revenues.asMap().entries.map((e) {
        return makeReport(
          id: '${e.key}',
          closedAt: DateTime(2024, 1, e.key + 1),
          netRevenue: e.value,
        );
      }).toList();

      final result = sut.analyze(reports);

      expect(result.revenueTrend.movingAverage7Day, expected);
    });
  });
}
