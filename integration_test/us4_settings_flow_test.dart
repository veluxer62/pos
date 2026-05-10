/// US4 통합 테스트: 메뉴·좌석 설정 CRUD
///
/// 실행: flutter test integration_test/us4_settings_flow_test.dart
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
import 'helpers/test_helpers.dart' as helpers;

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
  }

  // 설정 탭으로 이동하는 헬퍼 (영업일이 열려 있어야 ShellRoute 접근)
  Future<void> goToSettingsTab(WidgetTester tester) async {
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    expect(find.text('설정'), findsWidgets);
  }

  group('US4-A: 메뉴 관리', () {
    patrolTest('메뉴를 추가하면 목록에 반영된다', ($) async {
      final tester = $.tester;
      final businessDayDao = BusinessDayDao(testDb);
      await businessDayDao.open();

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await goToSettingsTab(tester);

      // 메뉴 관리 탭이 기본 선택
      expect(find.text('메뉴 관리'), findsWidgets);

      // + 버튼으로 메뉴 추가
      await tester.tap(find.byTooltip('메뉴 추가').first);
      await tester.pumpAndSettle();

      // 메뉴 이름 입력
      await tester.enterText(
        find.widgetWithText(TextFormField, '메뉴 이름'),
        '된장찌개',
      );
      // 가격 입력
      await tester.enterText(
        find.widgetWithText(TextFormField, '가격'),
        '7000',
      );
      // 카테고리 입력
      await tester.enterText(
        find.widgetWithText(TextFormField, '카테고리'),
        '찌개',
      );

      await tester.tap(find.text('추가'));
      await tester.pumpAndSettle();

      expect(find.text('된장찌개'), findsOneWidget);
    });

    patrolTest('등록된 메뉴가 없으면 안내 문구가 표시된다', ($) async {
      final tester = $.tester;
      final businessDayDao = BusinessDayDao(testDb);
      await businessDayDao.open();

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await goToSettingsTab(tester);

      expect(find.text('등록된 메뉴가 없습니다.'), findsOneWidget);
    });

    patrolTest('메뉴를 탭하면 수정 다이얼로그가 표시된다', ($) async {
      final tester = $.tester;
      final now = DateTime.now();
      final businessDayDao = BusinessDayDao(testDb);
      await businessDayDao.open();

      await testDb.into(testDb.menuItems).insert(
            MenuItemsCompanion.insert(
              id: 'menu-1',
              name: '김치찌개',
              price: 8000,
              category: '찌개',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await goToSettingsTab(tester);

      await tester.tap(find.text('김치찌개'));
      await tester.pumpAndSettle();

      // 수정 다이얼로그
      expect(find.text('수정'), findsOneWidget);
    });
  });

  group('US4-B: 좌석 관리', () {
    patrolTest('좌석 관리 탭으로 전환하면 좌석 목록이 표시된다', ($) async {
      final tester = $.tester;
      final now = DateTime.now();
      final businessDayDao = BusinessDayDao(testDb);
      await businessDayDao.open();

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

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await goToSettingsTab(tester);

      // 좌석 관리 탭 선택
      await tester.tap(find.text('좌석 관리'));
      await tester.pumpAndSettle();

      expect(find.text('A1'), findsOneWidget);
    });

    patrolTest('좌석을 추가하면 목록에 반영된다', ($) async {
      final tester = $.tester;
      final businessDayDao = BusinessDayDao(testDb);
      await businessDayDao.open();

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await goToSettingsTab(tester);

      await tester.tap(find.text('좌석 관리'));
      await tester.pumpAndSettle();

      // + 버튼
      await tester.tap(find.byTooltip('좌석 추가'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, '좌석 번호'),
        'B1',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '수용 인원'),
        '4',
      );

      await tester.tap(find.text('추가'));
      await tester.pumpAndSettle();

      expect(find.text('B1'), findsOneWidget);
    });

    patrolTest('등록된 좌석이 없으면 안내 문구가 표시된다', ($) async {
      final tester = $.tester;
      final businessDayDao = BusinessDayDao(testDb);
      await businessDayDao.open();

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await goToSettingsTab(tester);

      await tester.tap(find.text('좌석 관리'));
      await tester.pumpAndSettle();

      expect(find.text('등록된 좌석이 없습니다.'), findsOneWidget);
    });

    patrolTest('좌석 삭제 버튼 탭 시 확인 다이얼로그가 표시된다', ($) async {
      final tester = $.tester;
      final now = DateTime.now();
      final businessDayDao = BusinessDayDao(testDb);
      await businessDayDao.open();

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

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await goToSettingsTab(tester);

      await tester.tap(find.text('좌석 관리'));
      await tester.pumpAndSettle();

      // 삭제 아이콘 탭 (Semantics label: 'A1 좌석 삭제')
      await tester.tap(find.byTooltip('A1 좌석 삭제'));
      await tester.pumpAndSettle();

      // 확인 다이얼로그
      expect(find.text('좌석 삭제'), findsOneWidget);
    });
  });

  group('US4-C: 메뉴 수정·삭제', () {
    patrolTest('T-01: 메뉴 수정 후 목록에 반영된다', ($) async {
      final tester = $.tester;
      await helpers.insertMenuItem(testDb, name: '김치찌개', price: 8000);
      await helpers.openBusinessDay(testDb);

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await goToSettingsTab(tester);

      // 메뉴 관리 탭이 기본 선택 — '김치찌개' 탭으로 수정 다이얼로그 열기
      await tester.tap(find.text('김치찌개'));
      await tester.pumpAndSettle();

      // 이름 필드를 '된장찌개'로 교체
      await tester.enterText(
        find.widgetWithText(TextFormField, '메뉴 이름'),
        '된장찌개',
      );
      // 가격 필드를 '7000'으로 교체
      await tester.enterText(
        find.widgetWithText(TextFormField, '가격'),
        '7000',
      );

      await tester.tap(find.text('수정'));
      await tester.pumpAndSettle();

      expect(find.text('된장찌개'), findsOneWidget);
      expect(find.text('김치찌개'), findsNothing);
    });

    patrolTest('T-02: 메뉴 삭제 후 목록에서 사라진다', ($) async {
      final tester = $.tester;
      await helpers.insertMenuItem(testDb, name: '된장찌개', price: 7000);
      await helpers.openBusinessDay(testDb);

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await goToSettingsTab(tester);

      await tester.longPress(find.text('된장찌개'));
      await tester.pumpAndSettle();

      // 삭제 확인 다이얼로그
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(find.text('된장찌개'), findsNothing);
    });

    patrolTest('T-03: 활성 주문 참조 메뉴 삭제 시 판매 불가 처리된다', ($) async {
      final tester = $.tester;
      await helpers.insertMenuItem(testDb, id: 'menu-1', name: '김치찌개');
      await helpers.insertSeat(testDb, id: 'seat-1');
      final bd = await helpers.openBusinessDay(testDb);

      await OrderDao(testDb).create(
        businessDayId: bd.id,
        seatId: 'seat-1',
        items: [OrderItemInput(menuItemId: 'menu-1', quantity: 1)],
      );

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await goToSettingsTab(tester);

      await tester.longPress(find.text('김치찌개'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      // 활성 주문 참조 중이므로 삭제되지 않고 목록에 여전히 존재해야 함
      expect(find.text('김치찌개'), findsOneWidget);
    });
  });

  group('US4-D: 좌석 수정·삭제 제약', () {
    patrolTest('T-04: 좌석 수정 후 목록에 반영된다', ($) async {
      final tester = $.tester;
      await helpers.insertSeat(
        testDb,
        id: 'seat-1',
        seatNumber: 'A1',
        capacity: 4,
      );
      await helpers.openBusinessDay(testDb);

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await goToSettingsTab(tester);

      await tester.tap(find.text('좌석 관리'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('A1 좌석 수정'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, '좌석 번호'),
        'VIP1',
      );

      await tester.tap(find.text('수정'));
      await tester.pumpAndSettle();

      expect(find.text('VIP1'), findsOneWidget);
    });

    patrolTest('T-05: 활성 주문 연결 좌석 삭제 시도 시 차단된다', ($) async {
      final tester = $.tester;
      await helpers.insertSeat(testDb, id: 'seat-1', seatNumber: 'A1');
      await helpers.insertMenuItem(testDb);
      final bd = await helpers.openBusinessDay(testDb);

      await OrderDao(testDb).create(
        businessDayId: bd.id,
        seatId: 'seat-1',
        items: [],
      );

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await goToSettingsTab(tester);

      await tester.tap(find.text('좌석 관리'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('A1 좌석 삭제'));
      await tester.pumpAndSettle();

      // 확인 다이얼로그에서 삭제 확인
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      // 진행 중인 주문 연결로 삭제가 차단됨
      expect(
        find.text('진행 중인 주문이 연결된 좌석은 삭제할 수 없습니다.'),
        findsOneWidget,
      );
      expect(find.text('A1'), findsOneWidget);
    });
  });

  group('US4-E: 품절 메뉴 처리', () {
    patrolTest('T-14: 품절 메뉴는 주문 생성 화면에서 추가 불가 상태로 표시된다', ($) async {
      final tester = $.tester;
      await helpers.insertMenuItem(
        testDb,
        id: 'menu-1',
        name: '품절메뉴',
        isAvailable: false,
      );
      await helpers.insertSeat(testDb, id: 'seat-1', seatNumber: 'A1');
      await helpers.openBusinessDay(testDb);

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      // 좌석 'A1' 탭 → 주문 생성 페이지
      await tester.tap(find.text('A1'));
      await tester.pumpAndSettle();

      // 품절 메뉴는 표시되지만 추가 버튼이 비활성화 또는 없어야 함
      expect(find.text('품절메뉴'), findsOneWidget);

      // + 버튼이 없거나 탭해도 수량이 변하지 않아야 함
      final addButtons = find.byIcon(Icons.add_circle_outline);
      if (addButtons.evaluate().isNotEmpty) {
        // 버튼이 존재하는 경우 — 탭해도 품절 항목은 추가되지 않아야 함
        await tester.tap(addButtons.first);
        await tester.pumpAndSettle();

        // 총액이 여전히 0원이어야 함 (추가 불가)
        expect(find.text('0원'), findsOneWidget);
      }
      // 버튼이 없는 경우도 테스트 통과 (품절 메뉴에 + 버튼 자체가 없음)
    });
  });

  group('US4-F: 영업일 독립성', () {
    patrolTest('SC8: 새 영업일은 이전 영업일의 주문을 포함하지 않는다', ($) async {
      final tester = $.tester;
      final now = DateTime.now();
      final businessDayDao = BusinessDayDao(testDb);
      final orderDao = OrderDao(testDb);

      await testDb.into(testDb.seats).insert(
            SeatsCompanion.insert(
              id: 'seat-1',
              seatNumber: 'A1',
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

      // BD1: 주문 생성 → 결제 완료 → 마감
      final bd1 = await businessDayDao.open();
      final order = await orderDao.create(
        businessDayId: bd1.id,
        seatId: 'seat-1',
        items: const [],
      );
      await orderDao.deliver(order.id);
      await orderDao.payImmediate(order.id);
      await businessDayDao.closeBusinessDay();

      // BD2: 새 영업일 시작
      await businessDayDao.open();

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      // BD2에는 활성 주문 없음 — BD1 주문 미이월
      expect(find.text('준비중'), findsNothing);
      expect(find.text('전달 완료'), findsNothing);

      // A1 탭 → 주문 생성 화면 (빈 좌석)
      await tester.tap(find.text('A1'));
      await tester.pumpAndSettle();
      expect(find.text('주문 생성'), findsOneWidget);
    });
  });

  group('US5-F: 설정 변경 → 주문 화면 반영 및 좌석 삭제', () {
    patrolTest('SC1: 설정에서 추가한 메뉴가 주문 생성 화면에 즉시 표시된다', ($) async {
      final tester = $.tester;
      await helpers.insertSeat(testDb, id: 'seat-1', seatNumber: 'A1');
      await helpers.openBusinessDay(testDb);

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await goToSettingsTab(tester);

      // 메뉴 관리 → 새 메뉴 "제육볶음" 추가
      await tester.tap(find.byTooltip('메뉴 추가').first);
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

      // 주문 현황 탭으로 이동
      await tester.tap(find.text('주문 현황'));
      await tester.pumpAndSettle();

      // A1 좌석 탭 → 주문 생성 화면
      await tester.tap(find.text('A1'));
      await tester.pumpAndSettle();

      // 방금 추가한 메뉴가 선택 가능 목록에 표시됨
      expect(find.text('제육볶음'), findsOneWidget);
    });

    patrolTest('SC4: 활성 주문이 없는 좌석을 삭제하면 목록에서 사라진다', ($) async {
      final tester = $.tester;
      await helpers.insertSeat(testDb, id: 'seat-1', seatNumber: 'A1');
      await helpers.openBusinessDay(testDb);

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await goToSettingsTab(tester);

      await tester.tap(find.text('좌석 관리'));
      await tester.pumpAndSettle();

      // 삭제 아이콘 탭 → 확인 다이얼로그 → 확인
      await tester.tap(find.byTooltip('A1 좌석 삭제'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      // 활성 주문 없으므로 삭제 성공 — A1 사라짐
      expect(find.text('A1'), findsNothing);
    });
  });
}
