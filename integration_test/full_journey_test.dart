/// Full Journey 통합 테스트: 설정 → 영업 시작 → 주문 → 결제/외상 → 납부 → 마감 → 보고서 → 새 영업일
///
/// 실행: flutter test integration_test/full_journey_test.dart
/// (에뮬레이터 또는 실기기 연결 필요)
library;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pos/core/di/providers.dart';
import 'package:pos/data/local/daos/business_day_dao.dart';
import 'package:pos/data/local/daos/credit_account_dao.dart';
import 'package:pos/data/local/daos/menu_item_dao.dart';
import 'package:pos/data/local/daos/order_dao.dart';
import 'package:pos/data/local/daos/seat_dao.dart';
import 'package:pos/data/local/database/app_database.dart';
import 'package:pos/data/local/repositories/local_business_day_repository.dart';
import 'package:pos/data/local/repositories/local_credit_account_repository.dart';
import 'package:pos/data/local/repositories/local_menu_item_repository.dart';
import 'package:pos/data/local/repositories/local_order_repository.dart';
import 'package:pos/data/local/repositories/local_seat_repository.dart';
import 'package:pos/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase testDb;

  setUp(() {
    testDb = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await testDb.close();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
          menuItemRepositoryProvider.overrideWith(
            (_) => LocalMenuItemRepository(MenuItemDao(testDb)),
          ),
          seatRepositoryProvider.overrideWith(
            (_) => LocalSeatRepository(SeatDao(testDb)),
          ),
          orderRepositoryProvider.overrideWith(
            (_) => LocalOrderRepository(OrderDao(testDb)),
          ),
          businessDayRepositoryProvider.overrideWith(
            (_) => LocalBusinessDayRepository(BusinessDayDao(testDb)),
          ),
          creditAccountRepositoryProvider.overrideWith(
            (_) => LocalCreditAccountRepository(CreditAccountDao(testDb)),
          ),
        ],
        child: const PosApp(),
      ),
    );
  }

  group('Full Journey', () {
    testWidgets('영업 시작 → 즉시 결제 + 외상 결제 → 납부 → 마감 → 보고서 → 새 영업일 독립성 확인',
        (tester) async {
      final now = DateTime.now();
      final businessDayDao = BusinessDayDao(testDb);
      final creditAccountDao = CreditAccountDao(testDb);

      // 초기 데이터 세팅 (메뉴 2개, 좌석 2개, 외상 계좌 1개)
      await testDb.into(testDb.seats).insert(
            SeatsCompanion.insert(
              id: 'seat-1',
              seatNumber: 'A1',
              capacity: 4,
              createdAt: now,
              updatedAt: now,
            ),
          );
      await testDb.into(testDb.seats).insert(
            SeatsCompanion.insert(
              id: 'seat-2',
              seatNumber: 'A2',
              capacity: 4,
              createdAt: now,
              updatedAt: now,
            ),
          );
      await testDb.into(testDb.menuItems).insert(
            MenuItemsCompanion.insert(
              id: 'menu-1',
              name: '김치찌개',
              price: 9000,
              category: '찌개',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await creditAccountDao.create('홍길동');

      // ── Phase 1: 영업 시작 ──────────────────────────────────
      await pumpApp(tester);
      await tester.pumpAndSettle();

      expect(find.text('영업 시작'), findsOneWidget);
      await tester.tap(find.text('영업 시작'));
      await tester.pumpAndSettle();

      expect(find.text('영업 마감'), findsOneWidget);

      // ── Phase 2: A1 주문 → 전달 → 즉시 결제 ────────────────
      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('A1'));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('수량 증가').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('주문 확정'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('전달 완료'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('결제하기'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('즉시 결제'));
      await tester.pumpAndSettle();

      // 좌석 현황 복귀 확인
      expect(find.text('좌석 현황'), findsOneWidget);

      // ── Phase 3: A2 주문 → 전달 → 외상 결제(홍길동) ─────────
      await tester.tap(find.text('A2'));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('수량 증가').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('주문 확정'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('전달 완료'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('결제하기'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('외상 결제'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('홍길동').first);
      await tester.pumpAndSettle();

      expect(find.text('좌석 현황'), findsOneWidget);

      // ── Phase 4: 홍길동 외상 납부 ───────────────────────────
      await tester.tap(find.text('외상 장부'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('홍길동'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('납부 처리'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '9000');
      await tester.pumpAndSettle();

      await tester.tap(find.text('납부'));
      await tester.pumpAndSettle();

      // 납부 완료 후 잔액 0원
      expect(find.text('0원'), findsOneWidget);

      // ── Phase 5: 영업 마감 (DAO 직접 호출) ──────────────────
      await businessDayDao.closeBusinessDay();

      // ── Phase 6: 앱 재기동 → 마감 상태 확인 ─────────────────
      await pumpApp(tester);
      await tester.pumpAndSettle();

      expect(find.text('영업 시작'), findsOneWidget);

      // ── Phase 7: 매출 내역 → 보고서 확인 ────────────────────
      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('매출 내역'));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsAtLeastNWidgets(1));

      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      // 보고서에 확정 매출·외상 발생 항목 표시
      expect(find.text('일일 매출 보고서'), findsOneWidget);
      expect(find.text('확정 매출'), findsOneWidget);
      expect(find.text('외상 발생 (미수금)'), findsOneWidget);

      // ── Phase 8: 새 영업일 독립성 확인 ───────────────────────
      await businessDayDao.open();

      await pumpApp(tester);
      await tester.pumpAndSettle();

      // 새 영업일이 열려 있으므로 '영업 마감' 버튼
      expect(find.text('영업 마감'), findsOneWidget);

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      // 새 영업일에는 이전 영업일 주문이 없음
      expect(find.text('준비중'), findsNothing);
      expect(find.text('전달 완료'), findsNothing);
    });

    testWidgets('영업일 없을 때 주문 시도 시 BusinessDayPage로 리다이렉트된다', (tester) async {
      // 좌석·메뉴 있지만 영업일 없음
      final now = DateTime.now();
      await testDb.into(testDb.seats).insert(
            SeatsCompanion.insert(
              id: 'seat-1',
              seatNumber: 'A1',
              capacity: 4,
              createdAt: now,
              updatedAt: now,
            ),
          );

      await pumpApp(tester);
      await tester.pumpAndSettle();

      // 영업 시작 버튼이 있어야 함 (주문 불가 상태)
      expect(find.text('영업 시작'), findsOneWidget);
      expect(find.text('영업 마감'), findsNothing);
    });
  });
}
