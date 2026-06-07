import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pos/domain/entities/daily_sales_report.dart';
import 'package:pos/domain/entities/sales_analysis.dart';
import 'package:pos/domain/repositories/i_business_day_repository.dart';
import 'package:pos/domain/repositories/i_sales_analysis_service.dart';
import 'package:pos/domain/usecases/sales/get_sales_analysis_use_case.dart';

import 'get_sales_analysis_use_case_test.mocks.dart';

@GenerateMocks([IBusinessDayRepository, ISalesAnalysisService])
void main() {
  late MockIBusinessDayRepository mockRepo;
  late MockISalesAnalysisService mockService;
  late GetSalesAnalysisUseCase sut;

  final now = DateTime(2024, 6, 1);

  DailySalesReport makeReport(String id, DateTime date, int revenue) =>
      DailySalesReport(
        id: id,
        businessDayId: 'bd-$id',
        openedAt: date,
        closedAt: date,
        totalRevenue: revenue,
        paidOrderCount: 2,
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

  setUp(() {
    mockRepo = MockIBusinessDayRepository();
    mockService = MockISalesAnalysisService();
    sut = GetSalesAnalysisUseCase(
      businessDayRepository: mockRepo,
      salesAnalysisService: mockService,
    );
  });

  group('GetSalesAnalysisUseCase', () {
    test('getReports 결과를 서비스에 전달하고 SalesAnalysis를 반환한다', () async {
      final reports = [
        makeReport('1', now.subtract(const Duration(days: 2)), 100000),
        makeReport('2', now.subtract(const Duration(days: 1)), 120000),
        makeReport('3', now, 110000),
      ];
      final expected = SalesAnalysis.empty().copyWith(reportCount: 3);

      when(mockRepo.getReports(from: anyNamed('from'), to: anyNamed('to')))
          .thenAnswer((_) async => reports);
      when(mockService.analyze(reports)).thenReturn(expected);

      final result = await sut.execute();

      expect(result, expected);
      verify(mockService.analyze(reports)).called(1);
    });

    test('리포트가 없으면 빈 SalesAnalysis를 반환한다', () async {
      final empty = SalesAnalysis.empty();

      when(mockRepo.getReports(from: anyNamed('from'), to: anyNamed('to')))
          .thenAnswer((_) async => []);
      when(mockService.analyze([])).thenReturn(empty);

      final result = await sut.execute();

      expect(result.reportCount, 0);
      expect(result.hasEnoughData, isFalse);
    });

    test('days 파라미터가 날짜 범위에 반영된다', () async {
      when(mockRepo.getReports(from: anyNamed('from'), to: anyNamed('to')))
          .thenAnswer((_) async => []);
      when(mockService.analyze(any)).thenReturn(SalesAnalysis.empty());

      await sut.execute(days: 7);

      final captured = verify(
        mockRepo.getReports(
          from: captureAnyNamed('from'),
          to: captureAnyNamed('to'),
        ),
      ).captured;
      final from = captured[0] as DateTime;
      final to = captured[1] as DateTime;
      expect(to.difference(from).inDays, 7);
    });
  });
}
