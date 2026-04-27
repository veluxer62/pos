import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pos/domain/entities/business_day.dart';
import 'package:pos/domain/entities/daily_sales_report.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';
import 'package:pos/domain/repositories/i_business_day_repository.dart';
import 'package:pos/domain/usecases/business_day/close_business_day_use_case.dart';
import 'package:pos/domain/value_objects/business_day_status.dart';

import 'close_business_day_use_case_test.mocks.dart';

@GenerateMocks([IBusinessDayRepository])
void main() {
  late MockIBusinessDayRepository mockRepo;
  late CloseBusinessDayUseCase sut;

  final now = DateTime(2024);

  final closedDay = BusinessDay(
    id: 'bd-1',
    status: BusinessDayStatus.closed,
    openedAt: now,
    createdAt: now,
    closedAt: now,
  );

  final report = DailySalesReport(
    id: 'report-1',
    businessDayId: 'bd-1',
    openedAt: now,
    closedAt: now,
    totalRevenue: 50000,
    paidOrderCount: 3,
    creditedAmount: 10000,
    creditedOrderCount: 1,
    cancelledOrderCount: 0,
    refundedOrderCount: 0,
    refundedAmount: 0,
    netRevenue: 50000,
    menuSummaryJson: '[]',
    hourlySummaryJson: '[]',
    createdAt: now,
  );

  final closeResult = CloseResult(businessDay: closedDay, report: report);

  setUp(() {
    mockRepo = MockIBusinessDayRepository();
    sut = CloseBusinessDayUseCase(repository: mockRepo);
  });

  group('CloseBusinessDayUseCase', () {
    test('정상 마감 시 CloseResult(보고서 포함)를 반환한다', () async {
      when(mockRepo.close(forceClose: false))
          .thenAnswer((_) async => closeResult);

      final result = await sut.execute();

      expect(result.businessDay.status, BusinessDayStatus.closed);
      expect(result.report.totalRevenue, 50000);
      verify(mockRepo.close(forceClose: false)).called(1);
    });

    test('미처리 주문 존재 시 PendingOrdersExistException을 전파한다', () async {
      when(mockRepo.close(forceClose: false)).thenThrow(
        const PendingOrdersExistException(pendingCount: 2, deliveredCount: 1),
      );

      await expectLater(
        sut.execute(),
        throwsA(isA<PendingOrdersExistException>()),
      );
    });

    test('forceClose=true이면 미처리 주문을 무시하고 마감한다', () async {
      when(mockRepo.close(forceClose: true))
          .thenAnswer((_) async => closeResult);

      final result = await sut.execute(forceClose: true);

      expect(result.businessDay.status, BusinessDayStatus.closed);
      verify(mockRepo.close(forceClose: true)).called(1);
    });

    test('집계 수치 — totalRevenue, creditedAmount, paidOrderCount가 정확하다', () async {
      when(mockRepo.close(forceClose: false))
          .thenAnswer((_) async => closeResult);

      final result = await sut.execute();

      expect(result.report.totalRevenue, 50000);
      expect(result.report.creditedAmount, 10000);
      expect(result.report.paidOrderCount, 3);
      expect(result.report.creditedOrderCount, 1);
      expect(result.report.cancelledOrderCount, 0);
      expect(result.report.netRevenue, 50000);
    });
  });
}
