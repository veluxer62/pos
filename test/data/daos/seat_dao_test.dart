import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/data/local/daos/seat_dao.dart';
import 'package:pos/data/local/database/app_database.dart';

void main() {
  late AppDatabase db;
  late SeatDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = SeatDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('SeatDao', () {
    Future<String> insertSeat({
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
      return id;
    }

    test('findAll — 전체 좌석을 반환한다', () async {
      await insertSeat(id: 'seat-1', seatNumber: 'A1');
      await insertSeat(id: 'seat-2', seatNumber: 'A2');

      final result = await dao.findAll();

      expect(result.length, 2);
    });

    test('findAll — seatNumber 오름차순 정렬', () async {
      await insertSeat(id: 'seat-3', seatNumber: 'C1');
      await insertSeat(id: 'seat-1', seatNumber: 'A1');
      await insertSeat(id: 'seat-2', seatNumber: 'B1');

      final result = await dao.findAll();

      expect(result[0].seatNumber, 'A1');
      expect(result[1].seatNumber, 'B1');
      expect(result[2].seatNumber, 'C1');
    });

    test('중복 seatNumber 삽입 시 예외가 발생한다', () async {
      await insertSeat(id: 'seat-1', seatNumber: 'A1');

      await expectLater(
        insertSeat(id: 'seat-2', seatNumber: 'A1'),
        throwsException,
      );
    });

    test('findById — 존재하는 id이면 좌석을 반환한다', () async {
      await insertSeat(id: 'seat-1', seatNumber: 'A1', capacity: 4);

      final result = await dao.findById('seat-1');

      expect(result, isNotNull);
      expect(result!.seatNumber, 'A1');
      expect(result.capacity, 4);
    });

    test('findById — 존재하지 않는 id이면 null을 반환한다', () async {
      final result = await dao.findById('no-such-id');

      expect(result, isNull);
    });

    test('findBySeatNumber — 존재하는 번호이면 좌석을 반환한다', () async {
      await insertSeat(id: 'seat-1', seatNumber: 'A1');

      final result = await dao.findBySeatNumber('A1');

      expect(result, isNotNull);
      expect(result!.id, 'seat-1');
    });

    test('findBySeatNumber — 존재하지 않는 번호이면 null을 반환한다', () async {
      final result = await dao.findBySeatNumber('Z9');

      expect(result, isNull);
    });

    test('insert — 좌석을 삽입하고 반환한다', () async {
      final now = DateTime.now();
      final seat = await dao.insert(
        SeatsCompanion.insert(
          id: 'seat-1',
          seatNumber: 'B3',
          capacity: 6,
          createdAt: now,
          updatedAt: now,
        ),
      );

      expect(seat.id, 'seat-1');
      expect(seat.seatNumber, 'B3');
      expect(seat.capacity, 6);
    });

    test('updateRow — capacity를 수정하면 반영된다', () async {
      await insertSeat(id: 'seat-1', seatNumber: 'A1', capacity: 4);

      final updated = await dao.updateRow(
        'seat-1',
        SeatsCompanion(
          capacity: const Value(8),
          updatedAt: Value(DateTime.now()),
        ),
      );

      expect(updated.capacity, 8);
      expect(updated.seatNumber, 'A1');
    });

    test('deleteRow — 좌석을 삭제한다', () async {
      await insertSeat(id: 'seat-1', seatNumber: 'A1');

      await dao.deleteRow('seat-1');

      final result = await dao.findById('seat-1');
      expect(result, isNull);
    });
  });
}
