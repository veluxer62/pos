import 'package:pos/core/router/router.dart';
import 'package:pos/data/local/database/app_database.dart';
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

// 각 Phase에서 LocalXxxRepository 구현체로 교체 예정
@Riverpod(keepAlive: true)
IMenuItemRepository menuItemRepository(Ref _) {
  throw UnimplementedError('Phase 3에서 LocalMenuItemRepository로 교체');
}

@Riverpod(keepAlive: true)
ISeatRepository seatRepository(Ref _) {
  throw UnimplementedError('Phase 3에서 LocalSeatRepository로 교체');
}

@Riverpod(keepAlive: true)
IOrderRepository orderRepository(Ref _) {
  throw UnimplementedError('Phase 3에서 LocalOrderRepository로 교체');
}

@Riverpod(keepAlive: true)
IBusinessDayRepository businessDayRepository(Ref _) {
  throw UnimplementedError('Phase 3에서 LocalBusinessDayRepository로 교체');
}

@Riverpod(keepAlive: true)
ICreditAccountRepository creditAccountRepository(Ref _) {
  throw UnimplementedError('Phase 4에서 LocalCreditAccountRepository로 교체');
}

@Riverpod(keepAlive: true)
AppRouter appRouter(Ref _) {
  // TODO(Phase 3): businessDayRepository 연결 후 businessDayGuard 활성화
  return AppRouter();
}
