import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/data/local/daos/order_dao.dart';
import 'package:pos/data/local/database/app_database.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';
import 'package:pos/domain/repositories/i_order_repository.dart';
import 'package:pos/domain/value_objects/business_day_status.dart';
import 'package:pos/domain/value_objects/order_status.dart';

void main() {
  late AppDatabase db;
  late OrderDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = OrderDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('OrderDao', () {
    Future<void> seedPrerequisites({
      String businessDayId = 'bd-1',
      String seatId = 'seat-1',
      String menuId = 'menu-1',
    }) async {
      final now = DateTime.now();
      await db.into(db.businessDays).insert(
            BusinessDaysCompanion.insert(
              id: businessDayId,
              status: BusinessDayStatus.open,
              openedAt: now,
              createdAt: now,
            ),
          );
      await db.into(db.seats).insert(
            SeatsCompanion.insert(
              id: seatId,
              seatNumber: 'A1',
              capacity: 4,
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db.into(db.menuItems).insert(
            MenuItemsCompanion.insert(
              id: menuId,
              name: '아메리카노',
              price: 4500,
              category: '음료',
              createdAt: now,
              updatedAt: now,
            ),
          );
    }

    test('create — 주문과 항목을 생성하고 totalAmount를 계산한다', () async {
      await seedPrerequisites();

      final order = await dao.create(
        businessDayId: 'bd-1',
        seatId: 'seat-1',
        items: [
          OrderItemInput(menuItemId: 'menu-1', quantity: 2),
        ],
      );

      expect(order.businessDayId, 'bd-1');
      expect(order.seatId, 'seat-1');
      expect(order.status, isA<OrderStatusPending>());
      expect(order.totalAmount, 9000); // 4500 × 2
    });

    test('create — 여러 항목의 totalAmount를 합산한다', () async {
      await seedPrerequisites(menuId: 'menu-1');
      final now = DateTime.now();
      await db.into(db.menuItems).insert(
            MenuItemsCompanion.insert(
              id: 'menu-2',
              name: '라떼',
              price: 5000,
              category: '음료',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final order = await dao.create(
        businessDayId: 'bd-1',
        seatId: 'seat-1',
        items: [
          OrderItemInput(menuItemId: 'menu-1', quantity: 1),
          OrderItemInput(menuItemId: 'menu-2', quantity: 2),
        ],
      );

      expect(order.totalAmount, 14500); // 4500 + (5000 × 2) = 14500
    });

    test('findByBusinessDay — 해당 영업일의 주문 목록을 반환한다', () async {
      await seedPrerequisites();

      await dao.create(
        businessDayId: 'bd-1',
        seatId: 'seat-1',
        items: [OrderItemInput(menuItemId: 'menu-1', quantity: 1)],
      );

      final result = await dao.findByBusinessDay('bd-1');

      expect(result.length, 1);
      expect(result.first.businessDayId, 'bd-1');
    });

    test('findActiveOrderBySeat — PENDING 주문이 있으면 반환한다', () async {
      await seedPrerequisites();
      await dao.create(
        businessDayId: 'bd-1',
        seatId: 'seat-1',
        items: [OrderItemInput(menuItemId: 'menu-1', quantity: 1)],
      );

      final result = await dao.findActiveOrderBySeat('seat-1');

      expect(result, isNotNull);
      expect(result!.seatId, 'seat-1');
    });

    test('findActiveOrderBySeat — 활성 주문이 없으면 null을 반환한다', () async {
      await seedPrerequisites();

      final result = await dao.findActiveOrderBySeat('seat-1');

      expect(result, isNull);
    });

    test('deliver — PENDING → DELIVERED 전환', () async {
      await seedPrerequisites();
      final created = await dao.create(
        businessDayId: 'bd-1',
        seatId: 'seat-1',
        items: [OrderItemInput(menuItemId: 'menu-1', quantity: 1)],
      );

      final delivered = await dao.deliver(created.id);

      expect(delivered.status, isA<OrderStatusDelivered>());
      expect(delivered.deliveredAt, isNotNull);
    });

    test('cancel — PENDING → CANCELLED 전환', () async {
      await seedPrerequisites();
      final created = await dao.create(
        businessDayId: 'bd-1',
        seatId: 'seat-1',
        items: [OrderItemInput(menuItemId: 'menu-1', quantity: 1)],
      );

      final cancelled = await dao.cancel(created.id);

      expect(cancelled.status, isA<OrderStatusCancelled>());
      expect(cancelled.cancelledAt, isNotNull);
    });

    test('deliver — 존재하지 않는 orderId이면 OrderNotFoundException을 던진다', () async {
      await expectLater(
        dao.deliver('no-such-id'),
        throwsA(isA<OrderNotFoundException>()),
      );
    });

    test('cancel — 존재하지 않는 orderId이면 OrderNotFoundException을 던진다', () async {
      await expectLater(
        dao.cancel('no-such-id'),
        throwsA(isA<OrderNotFoundException>()),
      );
    });

    test('cancel — CANCELLED 상태에서 cancel 시 InvalidStateTransitionException',
        () async {
      await seedPrerequisites();
      final created = await dao.create(
        businessDayId: 'bd-1',
        seatId: 'seat-1',
        items: [OrderItemInput(menuItemId: 'menu-1', quantity: 1)],
      );
      await dao.cancel(created.id);

      await expectLater(
        dao.cancel(created.id),
        throwsA(isA<InvalidStateTransitionException>()),
      );
    });
  });
}
