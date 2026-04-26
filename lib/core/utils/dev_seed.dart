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

    batch.insert(
      db.businessDays,
      BusinessDaysCompanion.insert(
        id: uuid.v4(),
        status: BusinessDayStatus.open,
        openedAt: now,
        createdAt: now,
      ),
    );
  });
}
