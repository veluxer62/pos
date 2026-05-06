library;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:pos/domain/entities/business_day.dart';
import 'package:pos/main.dart';

Future<void> pumpTestApp(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        menuItemRepositoryProvider.overrideWith(
          (_) => LocalMenuItemRepository(MenuItemDao(db)),
        ),
        seatRepositoryProvider.overrideWith(
          (_) => LocalSeatRepository(SeatDao(db)),
        ),
        orderRepositoryProvider.overrideWith(
          (_) => LocalOrderRepository(OrderDao(db)),
        ),
        businessDayRepositoryProvider.overrideWith(
          (_) => LocalBusinessDayRepository(BusinessDayDao(db)),
        ),
        creditAccountRepositoryProvider.overrideWith(
          (_) => LocalCreditAccountRepository(CreditAccountDao(db)),
        ),
      ],
      child: const PosApp(),
    ),
  );
}

Future<void> insertSeat(
  AppDatabase db, {
  String id = 'seat-1',
  String seatNumber = 'A1',
  int capacity = 4,
}) async {
  final now = DateTime.now();
  await db.into(db.seats).insert(
        SeatsCompanion.insert(
          id: id,
          seatNumber: seatNumber,
          capacity: capacity,
          createdAt: now,
          updatedAt: now,
        ),
      );
}

Future<void> insertMenuItem(
  AppDatabase db, {
  String id = 'menu-1',
  String name = '김치찌개',
  int price = 8000,
  String category = '찌개',
  bool isAvailable = true,
}) async {
  final now = DateTime.now();
  await db.into(db.menuItems).insert(
        MenuItemsCompanion.insert(
          id: id,
          name: name,
          price: price,
          category: category,
          isAvailable: Value(isAvailable),
          createdAt: now,
          updatedAt: now,
        ),
      );
}

Future<BusinessDay> openBusinessDay(AppDatabase db) async {
  final dao = BusinessDayDao(db);
  return dao.open();
}
