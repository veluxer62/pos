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

    test('watchItemsByOrder — 초기 항목을 emit한다', () async {
      await seedPrerequisites();
      final order = await dao.create(
        businessDayId: 'bd-1',
        seatId: 'seat-1',
        items: [OrderItemInput(menuItemId: 'menu-1', quantity: 3)],
      );

      final items = await dao.watchItemsByOrder(order.id).first;

      expect(items.length, 1);
      expect(items.first.orderId, order.id);
      expect(items.first.quantity, 3);
    });

    test('watchItemsByOrder — 다른 orderId 항목은 포함하지 않는다', () async {
      await seedPrerequisites(seatId: 'seat-1');
      final now = DateTime.now();
      await db.into(db.seats).insert(
            SeatsCompanion.insert(
              id: 'seat-2',
              seatNumber: 'A2',
              capacity: 4,
              createdAt: now,
              updatedAt: now,
            ),
          );

      final order1 = await dao.create(
        businessDayId: 'bd-1',
        seatId: 'seat-1',
        items: [OrderItemInput(menuItemId: 'menu-1', quantity: 1)],
      );
      final order2 = await dao.create(
        businessDayId: 'bd-1',
        seatId: 'seat-2',
        items: [OrderItemInput(menuItemId: 'menu-1', quantity: 2)],
      );

      final items = await dao.watchItemsByOrder(order1.id).first;

      expect(items.length, 1);
      expect(items.every((i) => i.orderId == order1.id), isTrue);
      expect(items.any((i) => i.orderId == order2.id), isFalse);
    });

    group('addItem', () {
      test('항목 추가 후 totalAmount가 재계산된다', () async {
        await seedPrerequisites();
        final order = await dao.create(
          businessDayId: 'bd-1',
          seatId: 'seat-1',
          items: [OrderItemInput(menuItemId: 'menu-1', quantity: 1)],
        );
        expect(order.totalAmount, 4500);

        final updated = await dao.addItem(
          order.id,
          OrderItemInput(menuItemId: 'menu-1', quantity: 2),
        );

        expect(updated.totalAmount, 13500); // 4500 × 3
        final items = await dao.findItemsByOrder(order.id);
        expect(items.length, 2);
      });

      test('존재하지 않는 orderId이면 OrderNotFoundException을 던진다', () async {
        await seedPrerequisites();

        await expectLater(
          dao.addItem(
            'no-such-order',
            OrderItemInput(menuItemId: 'menu-1', quantity: 1),
          ),
          throwsA(isA<OrderNotFoundException>()),
        );
      });
    });

    group('removeItem', () {
      test('항목 삭제 후 totalAmount가 재계산된다', () async {
        await seedPrerequisites();
        final order = await dao.create(
          businessDayId: 'bd-1',
          seatId: 'seat-1',
          items: [
            OrderItemInput(menuItemId: 'menu-1', quantity: 2),
          ],
        );
        // 두 번째 항목 추가
        await dao.addItem(
          order.id,
          OrderItemInput(menuItemId: 'menu-1', quantity: 1),
        );
        final itemsBefore = await dao.findItemsByOrder(order.id);
        expect(itemsBefore.length, 2);

        // quantity=2(subtotal=9000)인 항목을 명시적으로 삭제 — 정렬 순서 무관
        final itemToRemove =
            itemsBefore.firstWhere((i) => i.quantity == 2);
        final updated = await dao.removeItem(order.id, itemToRemove.id);

        expect(updated.totalAmount, 4500); // 4500 × 1 남음
        final itemsAfter = await dao.findItemsByOrder(order.id);
        expect(itemsAfter.length, 1);
      });

      test('존재하지 않는 orderItemId이면 OrderItemNotFoundException을 던진다', () async {
        await seedPrerequisites();
        final order = await dao.create(
          businessDayId: 'bd-1',
          seatId: 'seat-1',
          items: [OrderItemInput(menuItemId: 'menu-1', quantity: 1)],
        );

        await expectLater(
          dao.removeItem(order.id, 'no-such-item'),
          throwsA(isA<OrderItemNotFoundException>()),
        );
      });
    });
  });
}
