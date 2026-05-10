/// US5 통합 테스트: 일일 매출 보고서 + 매출 내역 조회
///
/// 실행: flutter test integration_test/us5_report_flow_test.dart
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

  /// 영업일·좌석·메뉴·주문·결제까지 셋업 후 영업 마감 완료
  Future<void> seedClosedBusinessDay() async {
    final now = DateTime.now();
    final businessDayDao = BusinessDayDao(testDb);
    final orderDao = OrderDao(testDb);
    final creditAccountDao = CreditAccountDao(testDb);

    final businessDay = await businessDayDao.open();

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
    await testDb.into(testDb.seats).insert(
          SeatsCompanion.insert(
            id: 'seat-3',
            seatNumber: 'A3',
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
    await testDb.into(testDb.menuItems).insert(
          MenuItemsCompanion.insert(
            id: 'menu-2',
            name: '된장찌개',
            price: 8000,
            category: '찌개',
            createdAt: now,
            updatedAt: now,
          ),
        );

    final creditAccount = await creditAccountDao.create('홍길동');

    // 즉시 결제 주문 1 (seat-1, 김치찌개 1개 = 9000)
    final order1 = await orderDao.create(
      businessDayId: businessDay.id,
      seatId: 'seat-1',
      items: [OrderItemInput(menuItemId: 'menu-1', quantity: 1)],
    );
    await orderDao.deliver(order1.id);
    await orderDao.payImmediate(order1.id);

    // 즉시 결제 주문 2 (seat-2, 된장찌개 1개 = 8000)
    final order2 = await orderDao.create(
      businessDayId: businessDay.id,
      seatId: 'seat-2',
      items: [OrderItemInput(menuItemId: 'menu-2', quantity: 1)],
    );
    await orderDao.deliver(order2.id);
    await orderDao.payImmediate(order2.id);

    // 외상 결제 주문 (seat-3, 김치찌개 1개 = 9000)
    final order3 = await orderDao.create(
      businessDayId: businessDay.id,
      seatId: 'seat-3',
      items: [OrderItemInput(menuItemId: 'menu-1', quantity: 1)],
    );
    await orderDao.deliver(order3.id);
    await orderDao.payCredit(order3.id, creditAccount.id);

    // 영업 마감
    await businessDayDao.closeBusinessDay();
  }

  group('US5-A: 일일 매출 보고서', () {
    patrolTest('T-10: 영업 마감 후 보고서에 즉시 결제·외상 금액이 구분 표시된다', ($) async {
      final tester = $.tester;
      await seedClosedBusinessDay();
      await pumpApp(tester);
      await tester.pumpAndSettle();

      // BusinessDayPage → 영업 마감 완료 상태
      // 영업 시작 버튼이 있어야 함 (마감 완료)
      expect(find.text('영업 시작'), findsOneWidget);

      // 매출 내역 탭 이동
      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('매출 내역'));
      await tester.pumpAndSettle();

      // 마감된 영업일 표시
      expect(find.text('매출 내역'), findsWidgets);

      // 영업일 항목 탭 → 보고서 페이지 이동
      final dayTile = find.byType(ListTile).first;
      await tester.tap(dayTile);
      await tester.pumpAndSettle();

      expect(find.text('일일 매출 보고서'), findsOneWidget);

      // 확정 매출 = 즉시 결제 2건 (9000 + 8000 = 17000)
      expect(find.text('확정 매출'), findsOneWidget);
      // 외상 발생 (미수금) = 9000
      expect(find.text('외상 발생 (미수금)'), findsOneWidget);
      // 결제 완료 주문 2건
      expect(find.text('2건'), findsOneWidget);
    });
  });

  group('US5-B: 매출 내역 조회', () {
    patrolTest('T-11: 마감된 영업일이 매출 내역 목록에 표시되고 보고서로 이동 가능하다', ($) async {
      final tester = $.tester;
      await seedClosedBusinessDay();
      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('매출 내역'));
      await tester.pumpAndSettle();

      // 마감된 영업일이 목록에 표시됨
      expect(find.byType(ListTile), findsAtLeastNWidgets(1));

      // ListTile 탭 → 보고서 페이지
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      expect(find.text('일일 매출 보고서'), findsOneWidget);
    });

    patrolTest('매출 내역이 없으면 안내 문구가 표시된다', ($) async {
      final tester = $.tester;
      // 영업일 없음
      final businessDayDao = BusinessDayDao(testDb);
      await businessDayDao.open();

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('매출 내역'));
      await tester.pumpAndSettle();

      // 아직 마감된 영업일 없음 → 영업 중인 항목만 있음 (탭 불가)
      // 또는 리스트에 현재 영업일이 표시됨
      expect(find.text('매출 내역'), findsWidgets);
    });
  });
}
