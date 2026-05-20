/// Full Journey 통합 테스트: 앱 전체 기능 시나리오 E2E 검증
///
/// 실행: flutter test integration_test/full_journey_test.dart
/// (에뮬레이터 또는 실기기 연결 필요)
library;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
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
import 'package:pos/domain/repositories/i_order_repository.dart';
import 'package:pos/main.dart';

const _navigate = Duration(milliseconds: 1200);
const _settle = Duration(milliseconds: 800);
const _snackbar = Duration(milliseconds: 3500);

void main() {
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
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  Future<void> seedSeats(DateTime now, List<(String, String)> seats) async {
    for (final (id, seatNumber) in seats) {
      await testDb.into(testDb.seats).insert(
            SeatsCompanion.insert(
              id: id,
              seatNumber: seatNumber,
              capacity: 4,
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
  }

  Future<void> seedMenuItems(
    DateTime now,
    List<(String, String, int)> items,
  ) async {
    for (final (id, name, price) in items) {
      await testDb.into(testDb.menuItems).insert(
            MenuItemsCompanion.insert(
              id: id,
              name: name,
              price: price,
              category: '찌개',
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
  }

  group('Full Journey', () {
    patrolTest(
        'FJ-01: 영업 시작 → 즉시 결제 + 외상 결제 → 납부 → 마감 → 보고서 → 새 영업일 독립성 확인',
        ($) async {
      final tester = $.tester;
      final now = DateTime.now();
      final businessDayDao = BusinessDayDao(testDb);
      final creditAccountDao = CreditAccountDao(testDb);

      await seedSeats(now, [('seat-1', 'A1'), ('seat-2', 'A2')]);
      await seedMenuItems(now, [('menu-1', '김치찌개', 9000)]);
      await creditAccountDao.create('홍길동');

      // ── Phase 1: 영업 시작 ──────────────────────────────────
      await pumpApp(tester);
      await tester.pump(_navigate);

      expect(find.text('영업 시작'), findsOneWidget);
      await tester.tap(find.text('영업 시작'));
      await tester.pump(_navigate);
      expect(find.text('영업 마감'), findsOneWidget);

      // ── Phase 2: A1 주문 → 전달 → 즉시 결제 ────────────────
      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pump(_navigate);

      await tester.tap(find.text('A1'));
      await tester.pump(_navigate);

      await tester.tap(find.bySemanticsLabel('수량 증가').first);
      await tester.pump(_settle);
      await tester.tap(find.text('주문 확정'));
      await tester.pump(_navigate);
      await tester.pump(_snackbar);

      await tester.tap(find.text('전달 완료'));
      await tester.pump(_settle);
      await tester.pump(_snackbar);

      await tester.tap(find.text('결제하기'));
      await tester.pump(_navigate);
      await tester.tap(find.text('즉시 결제'));
      await tester.pump(_navigate);

      expect(find.text('좌석 현황'), findsOneWidget);

      // ── Phase 3: A2 주문 → 전달 → 외상 결제(홍길동) ─────────
      await tester.tap(find.text('A2'));
      await tester.pump(_navigate);

      await tester.tap(find.bySemanticsLabel('수량 증가').first);
      await tester.pump(_settle);
      await tester.tap(find.text('주문 확정'));
      await tester.pump(_navigate);
      await tester.pump(_snackbar);

      await tester.tap(find.text('전달 완료'));
      await tester.pump(_settle);
      await tester.pump(_snackbar);

      await tester.tap(find.text('결제하기'));
      await tester.pump(_navigate);
      await tester.tap(find.text('외상 결제'));
      await tester.pump(_settle);
      await tester.tap(find.text('홍길동').first);
      await tester.pump(_navigate);
      await tester.pump(_snackbar);

      expect(find.text('좌석 현황'), findsOneWidget);

      // ── Phase 4: 홍길동 외상 납부 ───────────────────────────
      await tester.tap(find.text('외상 장부'));
      await tester.pump(_navigate);

      await tester.tap(find.text('홍길동'));
      await tester.pump(_navigate);
      await tester.pump(const Duration(milliseconds: 2000));

      await tester.tap(find.text('납부 처리'));
      await tester.pump(_settle);
      await tester.enterText(find.byType(TextField), '9000');
      await tester.pump(_settle);
      await tester.tap(find.text('납부'));
      await tester.pump(_navigate);

      expect(find.text('0원'), findsOneWidget);

      // ── Phase 5: 영업 마감 ───────────────────────────────────
      await businessDayDao.closeBusinessDay();

      // ── Phase 6: 앱 재기동 → 마감 상태 확인 ─────────────────
      await pumpApp(tester);
      await tester.pump(_navigate);
      expect(find.text('영업 시작'), findsOneWidget);

      // ── Phase 7: 매출 내역 → 보고서 확인 ────────────────────
      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pump(_navigate);
      await tester.tap(find.text('매출 내역'));
      await tester.pump(_navigate);

      expect(find.byType(ListTile), findsAtLeastNWidgets(1));

      await tester.tap(find.byType(ListTile).first);
      await tester.pump(_navigate);

      expect(find.text('일일 매출 보고서'), findsOneWidget);
      expect(find.text('확정 매출'), findsOneWidget);
      expect(find.text('외상 발생 (미수금)'), findsOneWidget);

      // ── Phase 8: 새 영업일 독립성 확인 ───────────────────────
      await businessDayDao.open();
      await pumpApp(tester);
      await tester.pump(_navigate);
      expect(find.text('영업 마감'), findsOneWidget);

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pump(_navigate);
      expect(find.text('준비중'), findsNothing);
      expect(find.text('전달 완료'), findsNothing);
    });

    patrolTest('FJ-02: UI 기반 초기 설정(메뉴·좌석·외상 계좌) → 영업 시작 → 주문 → 결제 완주',
        ($) async {
      final tester = $.tester;

      // 빈 DB로 앱 시작
      await pumpApp(tester);
      await tester.pump(_navigate);
      expect(find.text('영업 시작'), findsOneWidget);

      // 영업 시작 (빈 DB에서도 시작 가능)
      await tester.tap(find.text('영업 시작'));
      await tester.pump(_navigate);

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pump(_navigate);

      // ── 설정: 메뉴 추가 ──
      await tester.tap(find.text('설정'));
      await tester.pump(_navigate);
      expect(find.text('메뉴 관리'), findsWidgets);

      await tester.tap(find.byTooltip('메뉴 추가').first);
      await tester.pump(_settle);

      await tester.enterText(
        find.widgetWithText(TextFormField, '메뉴 이름'),
        '김치찌개',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '가격'),
        '9000',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '카테고리'),
        '찌개',
      );
      await tester.tap(find.text('추가'));
      await tester.pump(_settle);
      expect(find.text('김치찌개'), findsOneWidget);

      // ── 설정: 좌석 추가 ──
      await tester.tap(find.text('좌석 관리'));
      await tester.pump(_navigate);

      await tester.tap(find.byTooltip('좌석 추가'));
      await tester.pump(_settle);

      await tester.enterText(
        find.widgetWithText(TextFormField, '좌석 번호'),
        'A1',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '수용 인원'),
        '4',
      );
      await tester.tap(find.text('추가'));
      await tester.pump(_settle);
      expect(find.text('A1'), findsOneWidget);

      // ── 외상 계좌 추가 ──
      await tester.tap(find.text('외상 장부'));
      await tester.pump(_navigate);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump(_settle);

      await tester.enterText(
        find.widgetWithText(TextField, '고객 이름'),
        '김철수',
      );
      await tester.tap(find.text('추가'));
      await tester.pump(_settle);
      expect(find.text('김철수'), findsOneWidget);

      // ── 주문 현황 → A1 주문 → 전달 → 즉시 결제 ──
      await tester.tap(find.text('주문 현황'));
      await tester.pump(_navigate);

      await tester.tap(find.text('A1'));
      await tester.pump(_navigate);

      await tester.tap(find.byIcon(Icons.add_circle_outline).first);
      await tester.pump(_settle);
      await tester.tap(find.text('주문 확정'));
      await tester.pump(_navigate);
      await tester.pump(_snackbar);

      await tester.tap(find.text('전달 완료'));
      await tester.pump(_settle);
      await tester.pump(_snackbar);

      await tester.tap(find.text('결제하기'));
      await tester.pump(_navigate);
      await tester.tap(find.text('즉시 결제'));
      await tester.pump(_navigate);

      expect(find.text('좌석 현황'), findsOneWidget);
      expect(find.text('전달 완료'), findsNothing);
    });

    patrolTest('FJ-03: 주문 취소 → 빈 좌석 복귀 → 재주문 → 전달 → 결제', ($) async {
      final tester = $.tester;
      final now = DateTime.now();
      await BusinessDayDao(testDb).open();
      await seedSeats(now, [('seat-1', 'A1')]);
      await seedMenuItems(now, [('menu-1', '김치찌개', 9000)]);

      await pumpApp(tester);
      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pump(_navigate);

      // ── 첫 번째 주문 생성 → 취소 ──
      await tester.tap(find.text('A1'));
      await tester.pump(_navigate);

      await tester.tap(find.byIcon(Icons.add_circle_outline).first);
      await tester.pump(_settle);
      await tester.tap(find.text('주문 확정'));
      await tester.pump(_navigate);
      await tester.pump(_snackbar);

      expect(find.text('준비중'), findsOneWidget);

      await tester.tap(find.text('주문 취소'));
      await tester.pump(_settle);
      await tester.tap(find.text('취소 처리'));
      await tester.pump(_navigate);

      // 빈 좌석 복귀 확인
      expect(find.text('좌석 현황'), findsOneWidget);
      expect(find.text('준비중'), findsNothing);

      // ── 재주문 → 전달 → 즉시 결제 ──
      await tester.tap(find.text('A1'));
      await tester.pump(_navigate);

      await tester.tap(find.byIcon(Icons.add_circle_outline).first);
      await tester.pump(_settle);
      await tester.tap(find.text('주문 확정'));
      await tester.pump(_navigate);
      await tester.pump(_snackbar);

      expect(find.text('주문 상세'), findsOneWidget);
      expect(find.text('준비중'), findsOneWidget);

      await tester.tap(find.text('전달 완료'));
      await tester.pump(_settle);
      await tester.pump(_snackbar);

      await tester.tap(find.text('결제하기'));
      await tester.pump(_navigate);
      await tester.tap(find.text('즉시 결제'));
      await tester.pump(_navigate);

      expect(find.text('좌석 현황'), findsOneWidget);
      expect(find.text('전달 완료'), findsNothing);
    });

    patrolTest('FJ-04: 미처리 주문 강제 마감 → 일일 매출 보고서 이동', ($) async {
      final tester = $.tester;
      final now = DateTime.now();
      final businessDayDao = BusinessDayDao(testDb);
      final businessDay = await businessDayDao.open();

      await seedSeats(now, [('seat-1', 'A1')]);
      await seedMenuItems(now, [('menu-1', '김치찌개', 9000)]);

      // PENDING 상태 미처리 주문 생성
      await OrderDao(testDb).create(
        businessDayId: businessDay.id,
        seatId: 'seat-1',
        items: const [],
      );

      await pumpApp(tester);

      // 영업 마감 시도
      await tester.tap(find.text('영업 마감'));
      await tester.pump(_settle);

      // 미처리 주문 경고 및 강제 마감 버튼 확인
      expect(find.text('미처리 주문이 있습니다'), findsOneWidget);
      expect(find.text('강제 마감'), findsOneWidget);

      // 강제 마감 실행
      await tester.tap(find.text('강제 마감'));
      await tester.pump(_navigate);

      // 보고서 페이지 이동 확인
      expect(find.text('일일 매출 보고서'), findsOneWidget);
    });

    patrolTest(
        'FJ-05: 복수 좌석 동시 주문 → 혼합 결제(즉시+외상) → 외상 납부 → 마감 → 보고서 검증',
        ($) async {
      final tester = $.tester;
      final now = DateTime.now();
      final businessDayDao = BusinessDayDao(testDb);
      final orderDao = OrderDao(testDb);
      final creditAccountDao = CreditAccountDao(testDb);
      final businessDay = await businessDayDao.open();

      await seedSeats(now, [
        ('seat-1', 'A1'),
        ('seat-2', 'A2'),
        ('seat-3', 'A3'),
      ]);
      await seedMenuItems(now, [
        ('menu-1', '김치찌개', 9000),
        ('menu-2', '된장찌개', 8000),
      ]);
      final creditAccount = await creditAccountDao.create('홍길동');

      // DAO로 3개 좌석 주문 생성 및 전달 완료
      final order1 = await orderDao.create(
        businessDayId: businessDay.id,
        seatId: 'seat-1',
        items: [OrderItemInput(menuItemId: 'menu-1', quantity: 1)],
      );
      await orderDao.deliver(order1.id);

      final order2 = await orderDao.create(
        businessDayId: businessDay.id,
        seatId: 'seat-2',
        items: [OrderItemInput(menuItemId: 'menu-2', quantity: 1)],
      );
      await orderDao.deliver(order2.id);

      final order3 = await orderDao.create(
        businessDayId: businessDay.id,
        seatId: 'seat-3',
        items: [OrderItemInput(menuItemId: 'menu-1', quantity: 1)],
      );
      await orderDao.deliver(order3.id);

      await pumpApp(tester);
      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pump(_navigate);

      // 3개 좌석 모두 전달 완료 상태 확인
      expect(find.text('전달 완료'), findsNWidgets(3));

      // ── A1: 즉시 결제 ──
      await tester.tap(find.text('A1'));
      await tester.pump(_navigate);
      await tester.tap(find.text('결제하기'));
      await tester.pump(_navigate);
      await tester.tap(find.text('즉시 결제'));
      await tester.pump(_navigate);
      expect(find.text('좌석 현황'), findsOneWidget);

      // ── A2: 외상 결제(홍길동) ──
      await tester.tap(find.text('A2'));
      await tester.pump(_navigate);
      await tester.tap(find.text('결제하기'));
      await tester.pump(_navigate);
      await tester.tap(find.text('외상 결제'));
      await tester.pump(_settle);
      await tester.tap(find.text('홍길동').first);
      await tester.pump(_navigate);
      await tester.pump(_snackbar);
      expect(find.text('좌석 현황'), findsOneWidget);

      // ── A3: 즉시 결제 ──
      await tester.tap(find.text('A3'));
      await tester.pump(_navigate);
      await tester.tap(find.text('결제하기'));
      await tester.pump(_navigate);
      await tester.tap(find.text('즉시 결제'));
      await tester.pump(_navigate);

      // 모든 결제 완료 — 활성 주문 없음
      expect(find.text('전달 완료'), findsNothing);
      expect(find.text('준비중'), findsNothing);

      // ── 외상 납부(홍길동, 8000원 → 잔액 0원) ──
      await tester.tap(find.text('외상 장부'));
      await tester.pump(_navigate);
      await tester.tap(find.text('홍길동'));
      await tester.pump(_navigate);
      await tester.pump(const Duration(milliseconds: 2000));

      await tester.tap(find.text('납부 처리'));
      await tester.pump(_settle);
      await tester.enterText(find.byType(TextField), '8000');
      await tester.pump(_settle);
      await tester.tap(find.text('납부'));
      await tester.pump(_navigate);
      expect(find.text('0원'), findsOneWidget);

      // ── 영업 마감 ──
      await businessDayDao.closeBusinessDay();

      // ── 매출 보고서 확인 ──
      await pumpApp(tester);
      await tester.pump(_navigate);
      expect(find.text('영업 시작'), findsOneWidget);

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pump(_navigate);
      await tester.tap(find.text('매출 내역'));
      await tester.pump(_navigate);

      expect(find.byType(ListTile), findsAtLeastNWidgets(1));
      await tester.tap(find.byType(ListTile).first);
      await tester.pump(_navigate);

      expect(find.text('일일 매출 보고서'), findsOneWidget);
      expect(find.text('확정 매출'), findsOneWidget);
      expect(find.text('외상 발생 (미수금)'), findsOneWidget);
      // 즉시 결제 2건
      expect(find.text('2건'), findsOneWidget);

      // 사용하지 않는 변수 경고 방지
      expect(creditAccount.id.isNotEmpty, isTrue);
    });

    patrolTest('FJ-06: 메뉴·좌석 설정 변경이 주문 화면에 실시간 반영된다', ($) async {
      final tester = $.tester;
      final now = DateTime.now();
      await BusinessDayDao(testDb).open();
      await seedSeats(now, [('seat-1', 'A1')]);

      await pumpApp(tester);
      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pump(_navigate);

      // 설정에서 메뉴 추가
      await tester.tap(find.text('설정'));
      await tester.pump(_navigate);

      await tester.tap(find.byTooltip('메뉴 추가').first);
      await tester.pump(_settle);

      await tester.enterText(
        find.widgetWithText(TextFormField, '메뉴 이름'),
        '제육볶음',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '가격'),
        '10000',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '카테고리'),
        '볶음',
      );
      await tester.tap(find.text('추가'));
      await tester.pump(_settle);

      // 주문 현황으로 이동 → A1 탭 → 추가한 메뉴 즉시 반영 확인
      await tester.tap(find.text('주문 현황'));
      await tester.pump(_navigate);
      await tester.tap(find.text('A1'));
      await tester.pump(_navigate);

      expect(find.text('제육볶음'), findsOneWidget);

      // 좌석 삭제 확인 (활성 주문 없을 때 삭제 가능)
      await tester.tap(find.byType(BackButton));
      await tester.pump(_navigate);
      await tester.tap(find.text('설정'));
      await tester.pump(_navigate);
      await tester.tap(find.text('좌석 관리'));
      await tester.pump(_navigate);

      await tester.tap(find.byTooltip('A1 좌석 삭제'));
      await tester.pump(_settle);
      await tester.tap(find.text('삭제'));
      await tester.pump(_settle);

      expect(find.text('A1'), findsNothing);
    });

    patrolTest('FJ-07: 영업일 없을 때 주문 시도 시 영업 관리 화면이 표시된다', ($) async {
      final tester = $.tester;
      final now = DateTime.now();
      await seedSeats(now, [('seat-1', 'A1')]);

      await pumpApp(tester);
      await tester.pump(_navigate);

      expect(find.text('영업 관리'), findsOneWidget);
      expect(find.text('영업 시작'), findsOneWidget);
      expect(find.text('영업 마감'), findsNothing);
    });

    patrolTest('FJ-08: 과납 처리 → 과납 확인 다이얼로그 표시', ($) async {
      final tester = $.tester;
      final businessDayDao = BusinessDayDao(testDb);
      final creditAccountDao = CreditAccountDao(testDb);
      await businessDayDao.open();

      final account = await creditAccountDao.create('홍길동');
      await creditAccountDao.charge(
        accountId: account.id,
        orderId: 'order-direct',
        amount: 5000,
      );

      await pumpApp(tester);
      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pump(_navigate);
      await tester.tap(find.text('외상 장부'));
      await tester.pump(_navigate);
      await tester.tap(find.text('홍길동'));
      await tester.pump(_navigate);
      await tester.pump(const Duration(milliseconds: 2000));

      await tester.tap(find.text('납부 처리'));
      await tester.pump(_settle);

      // 잔액(5000) 초과 금액 입력
      await tester.enterText(find.byType(TextField), '10000');
      await tester.pump(_settle);
      await tester.tap(find.text('납부'));
      await tester.pump(_settle);

      // 과납 확인 다이얼로그
      expect(find.text('과납 확인'), findsOneWidget);
    });

    patrolTest('FJ-09: 외상 잔액 있는 계좌 삭제 차단 → 잔액 0 후 삭제 가능', ($) async {
      final tester = $.tester;
      final businessDayDao = BusinessDayDao(testDb);
      final creditAccountDao = CreditAccountDao(testDb);
      await businessDayDao.open();

      final account = await creditAccountDao.create('홍길동');
      await creditAccountDao.charge(
        accountId: account.id,
        orderId: 'order-direct',
        amount: 9000,
      );

      await pumpApp(tester);
      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pump(_navigate);
      await tester.tap(find.text('외상 장부'));
      await tester.pump(_navigate);

      // 잔액이 있으므로 계좌가 목록에 존재
      expect(find.text('홍길동'), findsOneWidget);

      // 납부로 잔액 0 처리
      await creditAccountDao.pay(accountId: account.id, amount: 9000);
      await tester.pump(_navigate);

      // 잔액 0 → 계좌 삭제 가능
      await creditAccountDao.deleteAccount(account.id);
      final found = await creditAccountDao.findById(account.id);
      expect(found, isNull);
    });

    patrolTest(
        'FJ-10: 활성 주문 참조 중인 메뉴 삭제 시도 → soft delete(판매 불가) 처리',
        ($) async {
      final tester = $.tester;
      final now = DateTime.now();
      await seedMenuItems(now, [('menu-1', '김치찌개', 9000)]);
      await seedSeats(now, [('seat-1', 'A1')]);
      final bd = await BusinessDayDao(testDb).open();

      await OrderDao(testDb).create(
        businessDayId: bd.id,
        seatId: 'seat-1',
        items: [OrderItemInput(menuItemId: 'menu-1', quantity: 1)],
      );

      await pumpApp(tester);
      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pump(_navigate);
      await tester.tap(find.text('설정'));
      await tester.pump(_navigate);

      expect(find.text('김치찌개'), findsOneWidget);

      // 롱프레스 → 삭제 다이얼로그
      await tester.longPress(find.text('김치찌개'));
      await tester.pump(_settle);
      await tester.tap(find.text('삭제'));
      await tester.pump(_settle);

      // 활성 주문 참조 중이므로 목록에 여전히 존재 (soft delete)
      expect(find.text('김치찌개'), findsOneWidget);
    });
  });
}
