/// US2 통합 테스트: 즉시 결제 + 외상 결제 시나리오
///
/// 실행: flutter test integration_test/us2_payment_flow_test.dart
/// (에뮬레이터 또는 실기기 연결 필요)
library;

import 'package:drift/native.dart';
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

  /// 영업일 열고 좌석·메뉴·주문(전달 완료 상태)까지 셋업
  Future<String> seedDeliveredOrder() async {
    final now = DateTime.now();
    final businessDayDao = BusinessDayDao(testDb);
    final orderDao = OrderDao(testDb);

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

    final order = await orderDao.create(
      businessDayId: businessDay.id,
      seatId: 'seat-1',
      items: const [],
    );

    await orderDao.deliver(order.id);
    return order.id;
  }

  group('US2: 결제 플로우', () {
    testWidgets('주문 상세에서 결제하기 버튼으로 결제 페이지로 이동한다', (tester) async {
      await seedDeliveredOrder();
      await pumpApp(tester);
      await tester.pumpAndSettle();

      // BusinessDay가 열려있으므로 주문 관리 이동 버튼 탭
      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      // A1 좌석 탭 (전달 완료 상태)
      await tester.tap(find.text('A1'));
      await tester.pumpAndSettle();

      expect(find.text('주문 상세'), findsOneWidget);
      expect(find.text('결제하기'), findsOneWidget);

      // 결제하기 버튼 탭
      await tester.tap(find.text('결제하기'));
      await tester.pumpAndSettle();

      expect(find.text('결제'), findsOneWidget);
      expect(find.text('즉시 결제'), findsOneWidget);
      expect(find.text('외상 결제'), findsOneWidget);
    });

    testWidgets('즉시 결제 버튼 탭 시 결제 완료 후 주문 관리로 돌아간다', (tester) async {
      await seedDeliveredOrder();
      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('A1'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('결제하기'));
      await tester.pumpAndSettle();

      // 즉시 결제
      await tester.tap(find.text('즉시 결제'));
      await tester.pumpAndSettle();

      // 결제 완료 후 좌석 현황으로 복귀
      expect(find.text('좌석 현황'), findsWidgets);
    });

    testWidgets('외상 결제 탭 시 계좌 선택 UI가 표시된다', (tester) async {
      // 외상 계좌 미리 생성
      final creditAccountDao = CreditAccountDao(testDb);
      await creditAccountDao.create('홍길동');

      await seedDeliveredOrder();
      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('A1'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('결제하기'));
      await tester.pumpAndSettle();

      // 외상 결제 탭
      await tester.tap(find.text('외상 결제'));
      await tester.pumpAndSettle();

      // 외상 계좌 선택 다이얼로그
      expect(find.text('홍길동'), findsWidgets);
    });
  });
}
