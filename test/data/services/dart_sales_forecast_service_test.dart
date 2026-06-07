import 'package:flutter_test/flutter_test.dart';
import 'package:pos/data/local/services/dart_sales_forecast_service.dart';
import 'package:pos/domain/entities/daily_sales_report.dart';
import 'package:pos/domain/entities/sales_forecast.dart';

void main() {
  late DartSalesForecastService sut;

  setUp(() {
    sut = DartSalesForecastService();
  });

  DailySalesReport makeReport(DateTime date, int revenue) => DailySalesReport(
        id: date.toIso8601String(),
        businessDayId: 'bd',
        openedAt: date,
        closedAt: date,
        totalRevenue: revenue,
        paidOrderCount: 1,
        creditedAmount: 0,
        creditedOrderCount: 0,
        cancelledOrderCount: 0,
        refundedOrderCount: 0,
        refundedAmount: 0,
        netRevenue: revenue,
        menuSummaryJson: '[]',
        hourlySummaryJson: '[]',
        createdAt: date,
      );

  List<DailySalesReport> makeReports(int count, {int baseRevenue = 100000}) {
    final start = DateTime(2024, 1, 1);
    return List.generate(
      count,
      (i) => makeReport(
        start.add(Duration(days: i)),
        baseRevenue + (i % 3) * 10000,
      ),
    );
  }

  group('DartSalesForecastService', () {
    test('7일 미만 데이터이면 empty()를 반환한다', () {
      final reports = makeReports(5);
      final result = sut.forecast(reports);

      expect(result.forecastDays, isEmpty);
      expect(result.trainedOnDays, 0);
    });

    test('7일 이상 데이터에서 요청한 일수만큼 예측을 반환한다', () {
      final reports = makeReports(14);
      final result = sut.forecast(reports, forecastDays: 7);

      expect(result.forecastDays.length, 7);
    });

    test('예측 날짜가 마지막 리포트 다음 날부터 시작된다', () {
      final reports = makeReports(14);
      final lastDate = reports.last.closedAt;
      final result = sut.forecast(reports, forecastDays: 7);

      expect(
        result.forecastDays.first.date,
        lastDate.add(const Duration(days: 1)),
      );
    });

    test('예측 날짜가 연속된 7일이다', () {
      final reports = makeReports(14);
      final result = sut.forecast(reports, forecastDays: 7);

      for (var i = 1; i < result.forecastDays.length; i++) {
        final diff = result.forecastDays[i]
            .date
            .difference(result.forecastDays[i - 1].date)
            .inDays;
        expect(diff, 1);
      }
    });

    test('예측 매출이 0 이상이다', () {
      final reports = makeReports(30);
      final result = sut.forecast(reports, forecastDays: 7);

      for (final day in result.forecastDays) {
        expect(day.predictedRevenue, greaterThanOrEqualTo(0));
      }
    });

    test('source가 dartRegression이다', () {
      final reports = makeReports(14);
      final result = sut.forecast(reports);

      expect(result.source, ForecastSource.dartRegression);
    });

    test('trainedOnDays가 입력 리포트 수와 일치한다', () {
      final reports = makeReports(20);
      final result = sut.forecast(reports);

      expect(result.trainedOnDays, 20);
    });

    test('14일 이상이면 isReliable이 true이다', () {
      final reports = makeReports(14);
      final result = sut.forecast(reports);

      expect(result.isReliable, isTrue);
    });

    test('14일 미만이면 isReliable이 false이다', () {
      final reports = makeReports(10);
      final result = sut.forecast(reports);

      expect(result.isReliable, isFalse);
    });

    test('일정한 매출 패턴에서 예측값이 합리적인 범위에 있다', () {
      // 30일간 동일 매출 → 예측도 비슷한 수준이어야 함
      final reports = makeReports(30, baseRevenue: 200000);
      const maxRevenue = 200000 * 1.5;
      final result = sut.forecast(reports, forecastDays: 7);

      for (final day in result.forecastDays) {
        expect(day.predictedRevenue, lessThan(maxRevenue.toInt()));
      }
    });
  });
}
