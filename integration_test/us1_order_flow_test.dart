/// US1 통합 테스트: 영업 시작 → 주문 생성 → 전달 완료
///
/// 실행: flutter test integration_test/us1_order_flow_test.dart
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

  Future<void> seedData() async {
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
  }

  group('US1: 영업 시작 → 주문 생성 → 전달 완료', () {
    testWidgets('영업일이 없으면 BusinessDayPage로 리다이렉트된다', (tester) async {
      await pumpApp(tester);
      await tester.pumpAndSettle();

      expect(find.text('영업 관리'), findsOneWidget);
      expect(find.text('영업 시작'), findsOneWidget);
    });

    testWidgets('영업 시작 후 좌석 현황 페이지로 이동한다', (tester) async {
      await seedData();
      await pumpApp(tester);
      await tester.pumpAndSettle();

      // 영업 시작 버튼 탭
      await tester.tap(find.text('영업 시작'));
      await tester.pumpAndSettle();

      // 주문 관리로 이동 버튼 탭
      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      expect(find.text('좌석 현황'), findsOneWidget);
      expect(find.text('A1'), findsOneWidget);
    });

    testWidgets('좌석 탭 → 주문 생성 → 주문 상세에서 전달 완료 처리', (tester) async {
      await seedData();

      // 영업일 미리 열기
      final businessDayDao = BusinessDayDao(testDb);
      await businessDayDao.open();

      await pumpApp(tester);
      await tester.pumpAndSettle();

      // 주문 관리로 이동
      await tester.tap(find.text('주문 관리로 이동'));
      await tester.pumpAndSettle();

      // A1 좌석 탭
      await tester.tap(find.text('A1'));
      await tester.pumpAndSettle();

      // 주문 생성 페이지: 메뉴 선택
      expect(find.text('김치찌개'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add_circle_outline).first);
      await tester.pumpAndSettle();

      // 주문 접수 버튼 탭
      await tester.tap(find.text('주문 접수'));
      await tester.pumpAndSettle();

      // 주문 상세 페이지
      expect(find.text('주문 상세'), findsOneWidget);
      expect(find.text('준비중'), findsOneWidget);

      // 전달 완료 버튼 탭
      await tester.tap(find.text('전달 완료'));
      await tester.pumpAndSettle();

      expect(find.text('전달 완료'), findsWidgets);
    });
  });
}
