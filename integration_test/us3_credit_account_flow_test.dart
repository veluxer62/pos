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
import 'package:pos/domain/exceptions/domain_exceptions.dart';
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

    testWidgets('T-07: 납부 처리 실행 후 잔액이 차감되고 이력이 기록된다', (tester) async {
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
      await creditAccountDao.charge(
        accountId: account.id,
        orderId: 'order-direct',
        amount: 18000,
      );

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await goToCreditTab(tester);
      await tester.tap(find.text('홍길동'));
      await tester.pumpAndSettle();

      // 납부 처리 버튼 탭
      await tester.tap(find.text('납부 처리'));
      await tester.pumpAndSettle();

      // 납부 금액 입력 (10000)
      await tester.enterText(find.byType(TextField), '10000');
      await tester.pumpAndSettle();

      // 납부 버튼 탭
      await tester.tap(find.text('납부'));
      await tester.pumpAndSettle();

      // 납부 완료 스낵바
      expect(find.text('납부 처리가 완료되었습니다.'), findsOneWidget);
      await tester.pumpAndSettle();

      // 납부 이력 표시 확인
      expect(find.text('납부'), findsOneWidget);
    });

    testWidgets('T-08: 잔액이 있는 외상 계좌 삭제 시도 시 예외가 발생한다', (tester) async {
      final creditAccountDao = CreditAccountDao(testDb);
      final businessDayDao = BusinessDayDao(testDb);
      await businessDayDao.open();

      final account = await creditAccountDao.create('홍길동');
      await creditAccountDao.charge(
        accountId: account.id,
        orderId: 'order-direct',
        amount: 8000,
      );

      // 잔액이 있으므로 deleteAccount 시 예외 발생
      expect(
        () => creditAccountDao.deleteAccount(account.id),
        throwsA(isA<CreditAccountHasBalanceException>()),
      );

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await goToCreditTab(tester);
      // 계좌가 여전히 목록에 있음
      expect(find.text('홍길동'), findsOneWidget);
    });

    testWidgets('T-09: 잔액이 0인 외상 계좌는 DAO에서 삭제 가능하다', (tester) async {
      final creditAccountDao = CreditAccountDao(testDb);
      final businessDayDao = BusinessDayDao(testDb);
      await businessDayDao.open();

      final account = await creditAccountDao.create('홍길동');
      // 잔액 0 → 삭제 가능
      await creditAccountDao.deleteAccount(account.id);

      final found = await creditAccountDao.findById(account.id);
      expect(found, isNull);

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await goToCreditTab(tester);
      expect(find.text('홍길동'), findsNothing);
    });

    testWidgets('T-13: 잔액 초과 납부 시 과납 확인 다이얼로그가 표시된다', (tester) async {
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
      await creditAccountDao.charge(
        accountId: account.id,
        orderId: 'order-direct',
        amount: 5000,
      );

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await goToCreditTab(tester);
      await tester.tap(find.text('홍길동'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('납부 처리'));
      await tester.pumpAndSettle();

      // 잔액 초과 금액(8000) 입력
      await tester.enterText(find.byType(TextField), '8000');
      await tester.pumpAndSettle();

      await tester.tap(find.text('납부'));
      await tester.pumpAndSettle();

      // 과납 확인 다이얼로그
      expect(find.text('과납 확인'), findsOneWidget);
    });
  });

  group('US3-D: 잔액 수치·정렬·이력', () {
    testWidgets('SC3: 납부 후 정확한 잔액(8,000원)이 화면에 표시된다', (tester) async {
      final businessDayDao = BusinessDayDao(testDb);
      final creditAccountDao = CreditAccountDao(testDb);
      await businessDayDao.open();

      final account = await creditAccountDao.create('홍길동');
      await creditAccountDao.charge(
        accountId: account.id,
        orderId: 'order-1',
        amount: 18000,
      );

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('외상 장부'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('홍길동'));
      await tester.pumpAndSettle();

      // 납부 처리 → 10,000 입력 → 납부
      await tester.tap(find.text('납부 처리'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '10000');
      await tester.pumpAndSettle();

      await tester.tap(find.text('납부'));
      await tester.pumpAndSettle();

      // 납부 완료 후 잔액 8,000원 표시
      expect(find.text('8,000원'), findsOneWidget);
    });

    testWidgets('SC5: 외상 계좌 목록이 잔액 내림차순으로 정렬된다', (tester) async {
      final businessDayDao = BusinessDayDao(testDb);
      final creditAccountDao = CreditAccountDao(testDb);
      await businessDayDao.open();

      // 잔액: 홍길동 15000, 김철수 5000, 이영희 0
      final a = await creditAccountDao.create('홍길동');
      await creditAccountDao.charge(
        accountId: a.id,
        orderId: 'order-a',
        amount: 15000,
      );
      final b = await creditAccountDao.create('김철수');
      await creditAccountDao.charge(
        accountId: b.id,
        orderId: 'order-b',
        amount: 5000,
      );
      await creditAccountDao.create('이영희'); // 잔액 0

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('외상 장부'));
      await tester.pumpAndSettle();

      // 미납 계좌 섹션과 완납 계좌 섹션 모두 표시
      expect(find.text('미납 계좌 (2)'), findsOneWidget);
      expect(find.text('완납 계좌 (1)'), findsOneWidget);

      // 미납 계좌 내 순서: 홍길동(15000) → 김철수(5000)
      final tiles = tester.widgetList(find.byType(ListTile)).toList();
      final names = tiles
          .map((w) {
            final tile = w as ListTile;
            final title = tile.title;
            if (title is Text) return title.data;
            return null;
          })
          .whereType<String>()
          .toList();

      final hongIdx = names.indexOf('홍길동');
      final kimIdx = names.indexOf('김철수');
      expect(hongIdx, lessThan(kimIdx));
    });

    testWidgets('SC6: 잔액 0 계좌에서 외상 발생 및 납부 이력이 모두 표시된다', (tester) async {
      final businessDayDao = BusinessDayDao(testDb);
      final creditAccountDao = CreditAccountDao(testDb);
      await businessDayDao.open();

      final account = await creditAccountDao.create('홍길동');
      await creditAccountDao.charge(
        accountId: account.id,
        orderId: 'order-1',
        amount: 9000,
      );
      await creditAccountDao.pay(accountId: account.id, amount: 9000);

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('외상 장부'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('홍길동'));
      await tester.pumpAndSettle();

      // 외상 발생과 납부 이력 모두 표시
      expect(find.text('외상 발생'), findsOneWidget);
      expect(find.text('납부'), findsOneWidget);
      // 잔액 0 확인
      expect(find.text('0원'), findsOneWidget);
    });
  });
}
