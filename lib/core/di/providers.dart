import 'package:pos/core/router/router.dart';
import 'package:pos/data/local/daos/business_day_dao.dart';
import 'package:pos/data/local/daos/menu_item_dao.dart';
import 'package:pos/data/local/daos/order_dao.dart';
import 'package:pos/data/local/daos/seat_dao.dart';
import 'package:pos/data/local/database/app_database.dart';
import 'package:pos/data/local/repositories/local_business_day_repository.dart';
import 'package:pos/data/local/repositories/local_menu_item_repository.dart';
import 'package:pos/data/local/repositories/local_order_repository.dart';
import 'package:pos/data/local/repositories/local_seat_repository.dart';
import 'package:pos/domain/repositories/i_business_day_repository.dart';
import 'package:pos/domain/repositories/i_credit_account_repository.dart';
import 'package:pos/domain/repositories/i_menu_item_repository.dart';
import 'package:pos/domain/repositories/i_order_repository.dart';
import 'package:pos/domain/repositories/i_seat_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

@Riverpod(keepAlive: true)
IMenuItemRepository menuItemRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalMenuItemRepository(MenuItemDao(db));
}

@Riverpod(keepAlive: true)
ISeatRepository seatRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalSeatRepository(SeatDao(db));
}

@Riverpod(keepAlive: true)
IOrderRepository orderRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalOrderRepository(OrderDao(db));
}

@Riverpod(keepAlive: true)
IBusinessDayRepository businessDayRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalBusinessDayRepository(BusinessDayDao(db));
}

@Riverpod(keepAlive: true)
ICreditAccountRepository creditAccountRepository(Ref _) {
  throw UnimplementedError('Phase 4에서 LocalCreditAccountRepository로 교체');
}

@Riverpod(keepAlive: true)
AppRouter appRouter(Ref _) {
  return AppRouter();
}
