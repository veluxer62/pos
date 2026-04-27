import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/data/local/daos/business_day_dao.dart';
import 'package:pos/data/local/daos/order_dao.dart';
import 'package:pos/data/local/database/app_database.dart';
import 'package:pos/data/local/repositories/local_order_repository.dart';
import 'package:pos/domain/value_objects/order_status.dart';

void main() {
  late AppDatabase db;
  late LocalOrderRepository repository;
  late BusinessDayDao businessDayDao;
  late String businessDayId;
  late String seatId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    businessDayDao = BusinessDayDao(db);
    repository = LocalOrderRepository(OrderDao(db));

    final businessDay = await businessDayDao.open();
    businessDayId = businessDay.id;

    seatId = 'seat-1';
    await db.into(db.seats).insert(
          SeatsCompanion.insert(
            id: seatId,
            seatNumber: 'A1',
            capacity: 4,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
  });

  tearDown(() async => db.close());

  group('LocalOrderRepository', () {
    test('create — 주문을 생성한다', () async {
      final order = await repository.create(
        businessDayId: businessDayId,
        seatId: seatId,
        items: [],
      );

      expect(order.businessDayId, businessDayId);
      expect(order.seatId, seatId);
      expect(order.status, const OrderStatusPending());
    });

    test('findById — 주문을 반환한다', () async {
      final order = await repository.create(
        businessDayId: businessDayId,
        seatId: seatId,
        items: [],
      );

      final found = await repository.findById(order.id);

      expect(found?.id, order.id);
    });

    test('findById — 없으면 null을 반환한다', () async {
      final result = await repository.findById('nonexistent');

      expect(result, isNull);
    });

    test('findByBusinessDay — 영업일별 주문을 반환한다', () async {
      await repository.create(
        businessDayId: businessDayId,
        seatId: seatId,
        items: [],
      );

      final orders = await repository.findByBusinessDay(businessDayId);

      expect(orders.length, 1);
    });

    test('findByBusinessDay — status 필터를 적용한다', () async {
      final order = await repository.create(
        businessDayId: businessDayId,
        seatId: seatId,
        items: [],
      );
      await repository.deliver(order.id);

      final pending = await repository.findByBusinessDay(
        businessDayId,
        status: const OrderStatusPending(),
      );
      final delivered = await repository.findByBusinessDay(
        businessDayId,
        status: const OrderStatusDelivered(),
      );

      expect(pending.length, 0);
      expect(delivered.length, 1);
    });

    test('findActiveOrderBySeat — 활성 주문을 반환한다', () async {
      await repository.create(
        businessDayId: businessDayId,
        seatId: seatId,
        items: [],
      );

      final active = await repository.findActiveOrderBySeat(seatId);

      expect(active, isNotNull);
    });

    test('deliver — 주문을 전달 완료 상태로 변경한다', () async {
      final order = await repository.create(
        businessDayId: businessDayId,
        seatId: seatId,
        items: [],
      );

      final delivered = await repository.deliver(order.id);

      expect(delivered.status, const OrderStatusDelivered());
    });

    test('cancel — 주문을 취소한다', () async {
      final order = await repository.create(
        businessDayId: businessDayId,
        seatId: seatId,
        items: [],
      );

      final cancelled = await repository.cancel(order.id);

      expect(cancelled.status, const OrderStatusCancelled());
    });

    test('payImmediate — 즉시 결제 처리한다', () async {
      final order = await repository.create(
        businessDayId: businessDayId,
        seatId: seatId,
        items: [],
      );
      await repository.deliver(order.id);

      final paid = await repository.payImmediate(order.id);

      expect(paid.status, const OrderStatusPaid());
    });

    test('watchByBusinessDay — 주문 스트림을 반환한다', () async {
      await repository.create(
        businessDayId: businessDayId,
        seatId: seatId,
        items: [],
      );

      final stream = repository.watchByBusinessDay(businessDayId);
      final orders = await stream.first;

      expect(orders.length, 1);
    });
  });
}
