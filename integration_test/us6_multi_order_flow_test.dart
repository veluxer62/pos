/// US6 통합 테스트: 복수 좌석 동시 주문 및 개별 결제
///
/// 실행: flutter test integration_test/us6_multi_order_flow_test.dart
/// (에뮬레이터 또는 실기기 연결 필요)
library;

import 'package:drift/native.dart';
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
import 'package:pos/domain/value_objects/order_status.dart';
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

  group('US6-A: 복수 좌석 동시 주문', () {
    patrolTest('T-12: 두 좌석에 각각 주문 후 한 좌석만 결제해도 나머지 좌석은 유지된다', ($) async {
      final tester = $.tester;
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
              price: 8000,
              category: '찌개',
              createdAt: now,
              updatedAt: now,
            ),
          );

      // 두 좌석에 각각 주문 생성 후 전달 완료
      final order1 = await orderDao.create(
        businessDayId: businessDay.id,
        seatId: 'seat-1',
        items: const [],
      );
      await orderDao.deliver(order1.id);

      final order2 = await orderDao.create(
        businessDayId: businessDay.id,
        seatId: 'seat-2',
        items: const [],
      );
      await orderDao.deliver(order2.id);

      // A1 좌석 즉시 결제
      await orderDao.payImmediate(order1.id);

      // 상태 검증
      final updatedOrder1 = await orderDao.findById(order1.id);
      final updatedOrder2 = await orderDao.findById(order2.id);

      expect(updatedOrder1?.status, isA<OrderStatusPaid>());
      expect(updatedOrder2?.status, isA<OrderStatusDelivered>());

      // UI에서 좌석 현황 확인
      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      // A2 좌석은 전달 완료 상태 유지
      expect(find.text('전달 완료'), findsOneWidget);

      // A1 좌석 탭 → 주문 없음 (결제 완료 후 빈 좌석)
      await tester.tap(find.text('A1'));
      await tester.pumpAndSettle();

      // 주문 생성 페이지 (활성 주문 없음)
      expect(find.text('주문 확정'), findsOneWidget);
    });

    patrolTest('두 좌석 모두 주문 생성 후 좌석 그리드에 각각 상태가 표시된다', ($) async {
      final tester = $.tester;
      final now = DateTime.now();
      final businessDayDao = BusinessDayDao(testDb);
      final orderDao = OrderDao(testDb);

      final businessDay = await businessDayDao.open();

      await testDb.into(testDb.seats).insert(
            SeatsCompanion.insert(
              id: 'seat-1',
              seatNumber: 'B1',
              capacity: 4,
              createdAt: now,
              updatedAt: now,
            ),
          );
      await testDb.into(testDb.seats).insert(
            SeatsCompanion.insert(
              id: 'seat-2',
              seatNumber: 'B2',
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

      // B1: 준비중, B2: 전달 완료
      final order1 = await orderDao.create(
        businessDayId: businessDay.id,
        seatId: 'seat-1',
        items: const [],
      );

      final order2 = await orderDao.create(
        businessDayId: businessDay.id,
        seatId: 'seat-2',
        items: const [],
      );
      await orderDao.deliver(order2.id);

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      // B1 준비중, B2 전달 완료 상태 각각 표시
      expect(find.text('B1'), findsOneWidget);
      expect(find.text('B2'), findsOneWidget);
      expect(find.text('준비중'), findsOneWidget);
      expect(find.text('전달 완료'), findsOneWidget);

      // 사용하지 않는 변수 경고 방지
      expect(order1.id.isNotEmpty, isTrue);
    });
  });
}
