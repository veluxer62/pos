import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:pos/data/local/database/app_database.dart';
import 'package:pos/domain/value_objects/business_day_status.dart';
import 'package:uuid/uuid.dart';

/// debug 빌드에서만 호출. 앱 첫 실행 시 초기 데모 데이터를 삽입한다.
Future<void> seedDevData(AppDatabase db) async {
  assert(!kReleaseMode, 'seedDevData must not be called in release builds');

  final existing = await db.select(db.menuItems).get();
  if (existing.isNotEmpty) return;

  const uuid = Uuid();
  final now = DateTime.now();

  await db.batch((batch) {
    batch.insertAll(db.menuItems, [
      MenuItemsCompanion.insert(
        id: uuid.v4(),
        name: '아메리카노',
        price: 4500,
        category: '음료',
        createdAt: now,
        updatedAt: now,
      ),
      MenuItemsCompanion.insert(
        id: uuid.v4(),
        name: '카페라떼',
        price: 5000,
        category: '음료',
        createdAt: now,
        updatedAt: now,
      ),
      MenuItemsCompanion.insert(
        id: uuid.v4(),
        name: '녹차라떼',
        price: 5500,
        category: '음료',
        createdAt: now,
        updatedAt: now,
      ),
      MenuItemsCompanion.insert(
        id: uuid.v4(),
        name: '크로플',
        price: 7000,
        category: '디저트',
        createdAt: now,
        updatedAt: now,
      ),
      MenuItemsCompanion.insert(
        id: uuid.v4(),
        name: '치즈케이크',
        price: 7500,
        category: '디저트',
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    batch.insertAll(db.seats, [
      SeatsCompanion.insert(
        id: uuid.v4(),
        seatNumber: 'A1',
        capacity: 2,
        createdAt: now,
        updatedAt: now,
      ),
      SeatsCompanion.insert(
        id: uuid.v4(),
        seatNumber: 'A2',
        capacity: 2,
        createdAt: now,
        updatedAt: now,
      ),
      SeatsCompanion.insert(
        id: uuid.v4(),
        seatNumber: 'B1',
        capacity: 4,
        createdAt: now,
        updatedAt: now,
      ),
      SeatsCompanion.insert(
        id: uuid.v4(),
        seatNumber: 'B2',
        capacity: 4,
        createdAt: now,
        updatedAt: now,
      ),
      SeatsCompanion.insert(
        id: uuid.v4(),
        seatNumber: 'C1',
        capacity: 6,
        createdAt: now,
        updatedAt: now,
      ),
    ]);
  });

  // 14일치 마감 영업일 + DailySalesReport 생성 (매출 분석·예측 활성화)
  for (var i = 14; i >= 1; i--) {
    final date = now.subtract(Duration(days: i));
    final openedAt = DateTime(date.year, date.month, date.day, 9);
    final closedAt = DateTime(date.year, date.month, date.day, 22);

    // 요일(1=월~7=일)에 따른 매출 변동: 주말 높음
    final dow = date.weekday;
    final baseRevenue = (dow >= 6) ? 160000 : 100000;
    // 날짜별 의사 난수 변동 (±40,000)
    final variance = ((i * 7919 + dow * 3571) % 80000) - 40000;
    final totalRevenue = (baseRevenue + variance).clamp(40000, 250000);

    final americano = (totalRevenue * 0.35 ~/ 4500);
    final latte = (totalRevenue * 0.25 ~/ 5000);
    final greenLatte = (totalRevenue * 0.15 ~/ 5500);
    final croffle = (totalRevenue * 0.15 ~/ 7000);
    final cheesecake = (totalRevenue * 0.10 ~/ 7500);

    final menuSummary = [
      if (americano > 0)
        {'menuName': '아메리카노', 'quantity': americano, 'totalAmount': americano * 4500},
      if (latte > 0)
        {'menuName': '카페라떼', 'quantity': latte, 'totalAmount': latte * 5000},
      if (greenLatte > 0)
        {'menuName': '녹차라떼', 'quantity': greenLatte, 'totalAmount': greenLatte * 5500},
      if (croffle > 0)
        {'menuName': '크로플', 'quantity': croffle, 'totalAmount': croffle * 7000},
      if (cheesecake > 0)
        {'menuName': '치즈케이크', 'quantity': cheesecake, 'totalAmount': cheesecake * 7500},
    ];

    // 시간대별: 점심(12시)·오후(14시)·저녁(18시) 피크
    final hourlySummary = [
      {'hour': 10, 'orderCount': 2, 'totalAmount': totalRevenue ~/ 10},
      {'hour': 12, 'orderCount': 5, 'totalAmount': totalRevenue ~/ 4},
      {'hour': 14, 'orderCount': 4, 'totalAmount': totalRevenue ~/ 5},
      {'hour': 17, 'orderCount': 3, 'totalAmount': totalRevenue ~/ 7},
      {'hour': 19, 'orderCount': 4, 'totalAmount': totalRevenue ~/ 5},
      {'hour': 21, 'orderCount': 2, 'totalAmount': totalRevenue ~/ 10},
    ];

    final paidOrderCount = (americano + latte + greenLatte + croffle + cheesecake)
        .clamp(1, 999);

    final bdId = uuid.v4();
    await db.into(db.businessDays).insert(
      BusinessDaysCompanion(
        id: Value(bdId),
        status: const Value(BusinessDayStatus.closed),
        openedAt: Value(openedAt),
        closedAt: Value(closedAt),
        createdAt: Value(openedAt),
      ),
    );

    await db.into(db.dailySalesReports).insert(
      DailySalesReportsCompanion.insert(
        id: uuid.v4(),
        businessDayId: bdId,
        openedAt: openedAt,
        closedAt: closedAt,
        totalRevenue: totalRevenue,
        paidOrderCount: paidOrderCount,
        creditedAmount: 0,
        creditedOrderCount: 0,
        cancelledOrderCount: 0,
        refundedOrderCount: 0,
        refundedAmount: 0,
        netRevenue: totalRevenue,
        menuSummaryJson: jsonEncode(menuSummary),
        hourlySummaryJson: jsonEncode(hourlySummary),
        createdAt: closedAt,
      ),
    );
  }
}
