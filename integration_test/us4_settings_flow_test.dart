/// US4 통합 테스트: 메뉴·좌석 설정 CRUD
///
/// 실행: flutter test integration_test/us4_settings_flow_test.dart
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

  // 설정 탭으로 이동하는 헬퍼 (영업일이 열려 있어야 ShellRoute 접근)
  Future<void> goToSettingsTab(WidgetTester tester) async {
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    expect(find.text('설정'), findsWidgets);
  }

  group('US4-A: 메뉴 관리', () {
    testWidgets('메뉴를 추가하면 목록에 반영된다', (tester) async {
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

    testWidgets('등록된 메뉴가 없으면 안내 문구가 표시된다', (tester) async {
      final businessDayDao = BusinessDayDao(testDb);
      await businessDayDao.open();

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await goToSettingsTab(tester);

      expect(find.text('등록된 메뉴가 없습니다.'), findsOneWidget);
    });

    testWidgets('메뉴를 탭하면 수정 다이얼로그가 표시된다', (tester) async {
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
    testWidgets('좌석 관리 탭으로 전환하면 좌석 목록이 표시된다', (tester) async {
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

    testWidgets('좌석을 추가하면 목록에 반영된다', (tester) async {
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

    testWidgets('등록된 좌석이 없으면 안내 문구가 표시된다', (tester) async {
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

    testWidgets('좌석 삭제 버튼 탭 시 확인 다이얼로그가 표시된다', (tester) async {
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
}
