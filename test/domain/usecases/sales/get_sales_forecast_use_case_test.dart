import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pos/domain/entities/daily_sales_report.dart';
import 'package:pos/domain/entities/sales_forecast.dart';
import 'package:pos/domain/repositories/i_business_day_repository.dart';
import 'package:pos/domain/repositories/i_sales_forecast_service.dart';
import 'package:pos/domain/usecases/sales/get_sales_forecast_use_case.dart';

import 'get_sales_forecast_use_case_test.mocks.dart';

@GenerateMocks([IBusinessDayRepository, ISalesForecastService])
void main() {
  late MockIBusinessDayRepository mockRepo;
  late MockISalesForecastService mockService;
  late GetSalesForecastUseCase sut;

  final now = DateTime(2024, 6, 1);

  DailySalesReport makeReport(String id, DateTime date) => DailySalesReport(
        id: id,
        businessDayId: 'bd-$id',
        openedAt: date,
        closedAt: date,
        totalRevenue: 100000,
        paidOrderCount: 1,
        creditedAmount: 0,
        creditedOrderCount: 0,
        cancelledOrderCount: 0,
        refundedOrderCount: 0,
        refundedAmount: 0,
        netRevenue: 100000,
        menuSummaryJson: '[]',
        hourlySummaryJson: '[]',
        createdAt: date,
      );

  setUp(() {
    mockRepo = MockIBusinessDayRepository();
    mockService = MockISalesForecastService();
    sut = GetSalesForecastUseCase(
      businessDayRepository: mockRepo,
      salesForecastService: mockService,
    );
  });

  group('GetSalesForecastUseCase', () {
    test('getReports 결과를 서비스에 전달하고 SalesForecast를 반환한다', () async {
      final reports = List.generate(
        14,
        (i) => makeReport('$i', now.subtract(Duration(days: i))),
      );
      const expected = SalesForecast(
        forecastDays: [],
        source: ForecastSource.dartRegression,
        trainedOnDays: 14,
      );

      when(mockRepo.getReports(from: anyNamed('from'), to: anyNamed('to')))
          .thenAnswer((_) async => reports);
      when(mockService.forecast(reports, forecastDays: anyNamed('forecastDays')))
          .thenReturn(expected);

      final result = await sut.execute();

      expect(result.trainedOnDays, 14);
      verify(mockService.forecast(reports, forecastDays: 7)).called(1);
    });

    test('리포트가 없으면 empty를 반환한다', () async {
      when(mockRepo.getReports(from: anyNamed('from'), to: anyNamed('to')))
          .thenAnswer((_) async => []);
      when(mockService.forecast([], forecastDays: anyNamed('forecastDays')))
          .thenReturn(SalesForecast.empty());

      final result = await sut.execute();

      expect(result.forecastDays, isEmpty);
    });

    test('trainingDays가 날짜 범위에 반영된다', () async {
      when(mockRepo.getReports(from: anyNamed('from'), to: anyNamed('to')))
          .thenAnswer((_) async => []);
      when(mockService.forecast(any, forecastDays: anyNamed('forecastDays')))
          .thenReturn(SalesForecast.empty());

      await sut.execute(trainingDays: 90);

      final captured = verify(
        mockRepo.getReports(
          from: captureAnyNamed('from'),
          to: captureAnyNamed('to'),
        ),
      ).captured;
      final from = captured[0] as DateTime;
      final to = captured[1] as DateTime;
      expect(to.difference(from).inDays, 90);
    });
  });
}
