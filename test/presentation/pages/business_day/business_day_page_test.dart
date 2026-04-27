import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/domain/entities/business_day.dart';
import 'package:pos/domain/entities/daily_sales_report.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';
import 'package:pos/domain/repositories/i_business_day_repository.dart';
import 'package:pos/domain/usecases/business_day/close_business_day_use_case.dart';
import 'package:pos/domain/usecases/business_day/open_business_day_use_case.dart';
import 'package:pos/domain/value_objects/business_day_status.dart';
import 'package:pos/presentation/pages/business_day/business_day_page.dart';
import 'package:pos/presentation/providers/business_day_providers.dart';
import 'package:pos/presentation/widgets/app_error_widget.dart';

final _now = DateTime(2024, 1, 1, 9);

final _openDay = BusinessDay(
  id: 'bd-1',
  status: BusinessDayStatus.open,
  openedAt: _now,
  createdAt: _now,
);

Widget buildPage({
  required AsyncValue<BusinessDay?> openDayState,
  OpenBusinessDayUseCase? openUseCase,
  CloseBusinessDayUseCase? closeUseCase,
}) =>
    ProviderScope(
      overrides: [
        openBusinessDayProvider.overrideWith((_) {
          if (openDayState is AsyncLoading) {
            return const Stream.empty();
          } else if (openDayState is AsyncError) {
            return Stream.error((openDayState as AsyncError).error);
          } else {
            return Stream.value((openDayState as AsyncData<BusinessDay?>).value);
          }
        }),
        openBusinessDayUseCaseProvider.overrideWithValue(
          openUseCase ??
              OpenBusinessDayUseCase(repository: _StubBusinessDayRepository()),
        ),
        closeBusinessDayUseCaseProvider.overrideWithValue(
          closeUseCase ??
              CloseBusinessDayUseCase(repository: _StubBusinessDayRepository()),
        ),
      ],
      child: const MaterialApp(home: BusinessDayPage()),
    );

void main() {
  group('BusinessDayPage', () {
    testWidgets('로딩 중에는 CircularProgressIndicator가 표시된다', (tester) async {
      await tester.pumpWidget(
        buildPage(openDayState: const AsyncLoading()),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('오류 발생 시 AppErrorWidget이 표시된다', (tester) async {
      await tester.pumpWidget(
        buildPage(
          openDayState: AsyncError(
            Exception('테스트 오류'),
            StackTrace.empty,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorWidget), findsOneWidget);
    });

    testWidgets('영업일이 없으면 영업 시작 버튼이 표시된다', (tester) async {
      await tester.pumpWidget(
        buildPage(openDayState: const AsyncData(null)),
      );
      await tester.pumpAndSettle();

      expect(find.text('영업 시작'), findsOneWidget);
      expect(find.text('영업 마감'), findsNothing);
    });

    testWidgets('영업일이 있으면 영업 마감 버튼과 주문 관리 이동 버튼이 표시된다', (tester) async {
      await tester.pumpWidget(
        buildPage(openDayState: AsyncData(_openDay)),
      );
      await tester.pumpAndSettle();

      expect(find.text('영업 마감'), findsOneWidget);
      expect(find.text('주문 관리로 이동'), findsOneWidget);
      expect(find.text('영업 시작'), findsNothing);
    });

    testWidgets('영업일이 있으면 개시 시각이 표시된다', (tester) async {
      await tester.pumpWidget(
        buildPage(openDayState: AsyncData(_openDay)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('개시 시각'), findsOneWidget);
    });

    testWidgets('BusinessDayAlreadyOpenException 발생 시 오류 스낵바가 표시된다',
        (tester) async {
      final failUseCase = _ThrowingOpenUseCase(
        const BusinessDayAlreadyOpenException(),
      );

      await tester.pumpWidget(
        buildPage(
          openDayState: const AsyncData(null),
          openUseCase: failUseCase,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('영업 시작'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}

class _StubBusinessDayRepository implements IBusinessDayRepository {
  @override
  Future<BusinessDay> open() async => _openDay;

  @override
  Future<BusinessDay?> getOpen() async => null;

  static final _closedDay = _openDay.copyWith(
    status: BusinessDayStatus.closed,
    closedAt: DateTime(2024, 1, 1, 22),
  );

  static final _stubReport = DailySalesReport(
    id: 'r-1',
    businessDayId: 'bd-1',
    openedAt: _now,
    closedAt: DateTime(2024, 1, 1, 22),
    totalRevenue: 0,
    paidOrderCount: 0,
    creditedAmount: 0,
    creditedOrderCount: 0,
    cancelledOrderCount: 0,
    refundedOrderCount: 0,
    refundedAmount: 0,
    netRevenue: 0,
    menuSummaryJson: '[]',
    hourlySummaryJson: '[]',
    createdAt: DateTime(2024, 1, 1, 22),
  );

  @override
  Future<CloseResult> close({bool forceClose = false}) async => CloseResult(
        businessDay: _closedDay,
        report: _stubReport,
      );

  @override
  Future<BusinessDay?> findById(String id) async => null;

  @override
  Future<List<BusinessDay>> findAll({
    DateTime? from,
    DateTime? to,
    int limit = 30,
    int offset = 0,
  }) async => [];

  @override
  Future<DailySalesReport?> getReport(String businessDayId) async => null;

  @override
  Future<List<DailySalesReport>> getReports({
    required DateTime from,
    required DateTime to,
  }) async => [];

  @override
  Stream<BusinessDay?> watchOpen() => Stream.value(null);
}

class _ThrowingOpenUseCase extends OpenBusinessDayUseCase {
  _ThrowingOpenUseCase(this._exception)
      : super(repository: _StubBusinessDayRepository());

  final Exception _exception;

  @override
  Future<BusinessDay> execute() async => throw _exception;
}
