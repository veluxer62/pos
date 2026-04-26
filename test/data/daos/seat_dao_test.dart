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
  });
}
