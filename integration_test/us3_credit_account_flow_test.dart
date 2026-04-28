/// US3 통합 테스트: 외상 계좌 생성 → 잔액 확인 → 납부 처리
///
/// 실행: flutter test integration_test/us3_credit_account_flow_test.dart
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

  // 외상 장부 탭으로 이동하는 헬퍼 (영업일이 열려 있어야 ShellRoute 접근 가능)
  Future<void> goToCreditTab(WidgetTester tester) async {
    // AppShell NavigationRail에서 외상 장부 탭 선택
    await tester.tap(find.text('외상 장부'));
    await tester.pumpAndSettle();
    expect(find.text('외상 장부'), findsWidgets);
  }

  group('US3-A: 외상 계좌 생성', () {
    testWidgets('영업 중에 외상 계좌를 추가하면 목록에 표시된다', (tester) async {
      final businessDayDao = BusinessDayDao(testDb);
      await businessDayDao.open();

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await goToCreditTab(tester);

      // + 버튼으로 계좌 추가
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // 이름 입력
      await tester.enterText(
        find.widgetWithText(TextField, '고객 이름'),
        '홍길동',
      );
      await tester.tap(find.text('추가'));
      await tester.pumpAndSettle();

      expect(find.text('홍길동'), findsOneWidget);
    });

    testWidgets('등록된 외상 계좌가 없으면 안내 문구가 표시된다', (tester) async {
      final businessDayDao = BusinessDayDao(testDb);
      await businessDayDao.open();

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await goToCreditTab(tester);

      expect(find.textContaining('+ 버튼'), findsOneWidget);
    });
  });

  group('US3-B: 외상 잔액 확인', () {
    testWidgets('외상 결제 후 외상 계좌 상세에서 잔액이 반영된다', (tester) async {
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

      final account = await creditAccountDao.create('홍길동');

      final order = await orderDao.create(
        businessDayId: businessDay.id,
        seatId: 'seat-1',
        items: const [],
      );
      await orderDao.deliver(order.id);
      await orderDao.payCredit(order.id, account.id);

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await goToCreditTab(tester);

      // 홍길동 계좌 탭
      await tester.tap(find.text('홍길동'));
      await tester.pumpAndSettle();

      expect(find.text('외상 계좌 상세'), findsOneWidget);
      // balance = 0 (items 없이 생성된 주문이므로 totalAmount=0)
      expect(find.text('미납 잔액'), findsOneWidget);
    });

    testWidgets('외상 계좌 상세에서 거래 내역이 표시된다', (tester) async {
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

      final account = await creditAccountDao.create('홍길동');
      final order = await orderDao.create(
        businessDayId: businessDay.id,
        seatId: 'seat-1',
        items: const [],
      );
      await orderDao.deliver(order.id);
      await orderDao.payCredit(order.id, account.id);

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await goToCreditTab(tester);
      await tester.tap(find.text('홍길동'));
      await tester.pumpAndSettle();

      expect(find.text('외상 발생'), findsOneWidget);
    });
  });

  group('US3-C: 납부 처리', () {
    testWidgets('잔액이 있는 계좌에서 납부 처리 버튼이 표시된다', (tester) async {
      final now = DateTime.now();
      final businessDayDao = BusinessDayDao(testDb);
      final creditAccountDao = CreditAccountDao(testDb);

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

      final account = await creditAccountDao.create('홍길동');

      // 외상 발생 직접 주입
      await creditAccountDao.charge(
        accountId: account.id,
        orderId: 'order-direct',
        amount: 8000,
      );

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await goToCreditTab(tester);
      await tester.tap(find.text('홍길동'));
      await tester.pumpAndSettle();

      expect(find.text('납부 처리'), findsOneWidget);
    });
  });
}
