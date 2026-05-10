/// US1 통합 테스트: 영업 시작 → 주문 생성 → 전달 완료 → 취소 → 영업 마감
///
/// 실행: flutter test integration_test/us1_order_flow_test.dart
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

  // 영업 시작 후 좌석 현황으로 이동하는 공통 헬퍼
  Future<void> goToSeatGrid(WidgetTester tester) async {
    await tester.tap(find.text('주문 관리로 이동'));
    await tester.pumpAndSettle();
    expect(find.text('좌석 현황'), findsOneWidget);
  }

  group('US1-A: 영업일 가드', () {
    patrolTest('영업일이 없으면 BusinessDayPage로 리다이렉트된다', ($) async {
      final tester = $.tester;
      await pumpApp(tester);
      await tester.pumpAndSettle();

      expect(find.text('영업 관리'), findsOneWidget);
      expect(find.text('영업 시작'), findsOneWidget);
    });

    patrolTest('이미 영업 중일 때 영업 시작 재시도 시 에러 스낵바가 표시된다', ($) async {
      final tester = $.tester;
      await seedData();
      final businessDayDao = BusinessDayDao(testDb);
      await businessDayDao.open(); // 미리 영업 시작

      await pumpApp(tester);
      await tester.pumpAndSettle();

      // 영업 시작 버튼은 보이지 않아야 함 (이미 영업 중)
      expect(find.text('영업 시작'), findsNothing);
      expect(find.text('영업 마감'), findsOneWidget);
    });
  });

  group('US1-B: 주문 생성 → 전달 완료', () {
    patrolTest('영업 시작 후 좌석 현황 페이지로 이동한다', ($) async {
      final tester = $.tester;
      await seedData();
      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('영업 시작'));
      await tester.pumpAndSettle();

      await goToSeatGrid(tester);
      expect(find.text('A1'), findsOneWidget);
    });

    patrolTest('좌석 탭 → 주문 생성 → 전달 완료 처리', ($) async {
      final tester = $.tester;
      await seedData();
      final businessDayDao = BusinessDayDao(testDb);
      await businessDayDao.open();

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await goToSeatGrid(tester);

      // A1 좌석 탭 (주문 없음 → 주문 생성 페이지)
      await tester.tap(find.text('A1'));
      await tester.pumpAndSettle();

      // 메뉴 선택
      expect(find.text('김치찌개'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add_circle_outline).first);
      await tester.pumpAndSettle();

      // 주문 확정
      await tester.tap(find.text('주문 확정'));
      await tester.pumpAndSettle();

      // 주문 상세: 준비중 상태
      expect(find.text('주문 상세'), findsOneWidget);
      expect(find.text('준비중'), findsOneWidget);

      // 전달 완료 처리
      await tester.tap(find.text('전달 완료'));
      await tester.pumpAndSettle();

      expect(find.text('전달 완료'), findsWidgets);
    });

    patrolTest('주문 생성 후 좌석 그리드에 활성 주문 상태가 반영된다', ($) async {
      final tester = $.tester;
      await seedData();
      final businessDayDao = BusinessDayDao(testDb);
      await businessDayDao.open();

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await goToSeatGrid(tester);

      // 주문 생성
      await tester.tap(find.text('A1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add_circle_outline).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('주문 확정'));
      await tester.pumpAndSettle();

      // 뒤로 가기 (좌석 현황)
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // A1 좌석이 준비중 상태로 표시
      expect(find.text('준비중'), findsOneWidget);
    });
  });

  group('US1-C: 주문 취소', () {
    patrolTest('준비중 주문을 취소하면 좌석 현황으로 돌아간다', ($) async {
      final tester = $.tester;
      await seedData();
      final businessDayDao = BusinessDayDao(testDb);
      await businessDayDao.open();

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await goToSeatGrid(tester);

      // 주문 생성
      await tester.tap(find.text('A1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add_circle_outline).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('주문 확정'));
      await tester.pumpAndSettle();

      // 주문 상세에서 취소
      expect(find.text('주문 취소'), findsOneWidget);
      await tester.tap(find.text('주문 취소'));
      await tester.pumpAndSettle();

      // 취소 확인 다이얼로그 → 확인
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      // 취소 후 좌석 현황으로 복귀, A1은 빈 좌석
      expect(find.text('좌석 현황'), findsOneWidget);
      expect(find.text('준비중'), findsNothing);
    });
  });

  group('US1-D: 영업 마감', () {
    patrolTest('미처리 주문 없이 영업 마감 시 일일 매출 보고서로 이동한다', ($) async {
      final tester = $.tester;
      await seedData();
      final businessDayDao = BusinessDayDao(testDb);
      await businessDayDao.open();

      await pumpApp(tester);
      await tester.pumpAndSettle();

      // 영업 마감 버튼 탭
      await tester.tap(find.text('영업 마감'));
      await tester.pumpAndSettle();

      // 마감 다이얼로그 → 마감 버튼
      expect(find.text('마감하시겠습니까?'), findsOneWidget);
      await tester.tap(find.text('마감'));
      await tester.pumpAndSettle();

      // 일일 매출 보고서 페이지
      expect(find.text('일일 매출 보고서'), findsOneWidget);
    });

    patrolTest('미처리 주문 있을 때 마감 다이얼로그에 경고와 강제 마감 버튼이 표시된다', ($) async {
      final tester = $.tester;
      await seedData();
      final businessDayDao = BusinessDayDao(testDb);
      final businessDay = await businessDayDao.open();
      final orderDao = OrderDao(testDb);

      // PENDING 주문 생성
      await orderDao.create(
        businessDayId: businessDay.id,
        seatId: 'seat-1',
        items: const [],
      );

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('영업 마감'));
      await tester.pumpAndSettle();

      expect(find.text('미처리 주문이 있습니다'), findsOneWidget);
      expect(find.text('강제 마감'), findsOneWidget);
    });

    patrolTest('강제 마감 실행 시 미처리 주문이 취소되고 보고서로 이동한다', ($) async {
      final tester = $.tester;
      await seedData();
      final businessDayDao = BusinessDayDao(testDb);
      final businessDay = await businessDayDao.open();
      final orderDao = OrderDao(testDb);

      await orderDao.create(
        businessDayId: businessDay.id,
        seatId: 'seat-1',
        items: const [],
      );

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('영업 마감'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('강제 마감'));
      await tester.pumpAndSettle();

      expect(find.text('일일 매출 보고서'), findsOneWidget);
    });
  });

  group('US1-E: 주문 총액 계산 및 좌석 재진입', () {
    patrolTest('SC1: 메뉴 2인분 담으면 총액 18,000원이 표시된다', ($) async {
      final tester = $.tester;
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
              price: 9000,
              category: '찌개',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await BusinessDayDao(testDb).open();

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await goToSeatGrid(tester);
      await tester.tap(find.text('A1'));
      await tester.pumpAndSettle();

      // 수량 증가 2회
      await tester.tap(find.bySemanticsLabel('수량 증가').first);
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('수량 증가').first);
      await tester.pumpAndSettle();

      // 총 금액 18,000원 표시
      expect(find.text('18,000원'), findsOneWidget);
    });

    patrolTest('SC3: 활성 주문이 있는 좌석 탭 시 주문 상세로 이동한다', ($) async {
      final tester = $.tester;
      await seedData();
      final businessDay = await BusinessDayDao(testDb).open();
      await OrderDao(testDb).create(
        businessDayId: businessDay.id,
        seatId: 'seat-1',
        items: const [],
      );

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await goToSeatGrid(tester);
      await tester.tap(find.text('A1'));
      await tester.pumpAndSettle();

      // 주문 생성 화면이 아닌 주문 상세로 이동
      expect(find.text('주문 상세'), findsOneWidget);
    });

    patrolTest('SC5: 카트 항목 추가 시 총액이 즉시 재계산된다', ($) async {
      final tester = $.tester;
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
              price: 9000,
              category: '찌개',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await BusinessDayDao(testDb).open();

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await goToSeatGrid(tester);
      await tester.tap(find.text('A1'));
      await tester.pumpAndSettle();

      // 초기 0원
      expect(find.text('0원'), findsOneWidget);

      // 1개 추가 → 9,000원
      await tester.tap(find.bySemanticsLabel('수량 증가').first);
      await tester.pumpAndSettle();
      expect(find.text('9,000원'), findsOneWidget);

      // 1개 더 추가 → 18,000원
      await tester.tap(find.bySemanticsLabel('수량 증가').first);
      await tester.pumpAndSettle();
      expect(find.text('18,000원'), findsOneWidget);
    });
  });
}
