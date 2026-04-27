import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/data/local/daos/seat_dao.dart';
import 'package:pos/data/local/database/app_database.dart';
import 'package:pos/data/local/repositories/local_seat_repository.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';

void main() {
  late AppDatabase db;
  late LocalSeatRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = LocalSeatRepository(SeatDao(db));
  });

  tearDown(() async => db.close());

  group('LocalSeatRepository', () {
    test('create — 좌석을 생성한다', () async {
      final seat = await repository.create(seatNumber: 'A1', capacity: 4);

      expect(seat.seatNumber, 'A1');
      expect(seat.capacity, 4);
    });

    test('create — 중복 좌석 번호이면 DuplicateSeatNumberException이 발생한다', () async {
      await repository.create(seatNumber: 'A1', capacity: 4);

      await expectLater(
        repository.create(seatNumber: 'A1', capacity: 2),
        throwsA(isA<DuplicateSeatNumberException>()),
      );
    });

    test('findAll — 전체 좌석을 반환한다', () async {
      await repository.create(seatNumber: 'A1', capacity: 4);
      await repository.create(seatNumber: 'B1', capacity: 2);

      final seats = await repository.findAll();

      expect(seats.length, 2);
    });

    test('findById — 존재하는 좌석을 반환한다', () async {
      final created = await repository.create(seatNumber: 'A1', capacity: 4);

      final found = await repository.findById(created.id);

      expect(found?.id, created.id);
    });

    test('findById — 없으면 null을 반환한다', () async {
      final result = await repository.findById('nonexistent');

      expect(result, isNull);
    });

    test('findBySeatNumber — 번호로 좌석을 찾는다', () async {
      await repository.create(seatNumber: 'A1', capacity: 4);

      final found = await repository.findBySeatNumber('A1');

      expect(found?.seatNumber, 'A1');
    });

    test('update — 좌석 정보를 수정한다', () async {
      final seat = await repository.create(seatNumber: 'A1', capacity: 4);

      final updated = await repository.update(seat.id, capacity: 6);

      expect(updated.capacity, 6);
    });

    test('update — 존재하지 않으면 SeatNotFoundException이 발생한다', () async {
      await expectLater(
        repository.update('nonexistent', capacity: 4),
        throwsA(isA<SeatNotFoundException>()),
      );
    });

    test('update — 다른 좌석의 번호와 중복되면 DuplicateSeatNumberException이 발생한다',
        () async {
      await repository.create(seatNumber: 'A1', capacity: 4);
      final seat2 = await repository.create(seatNumber: 'B1', capacity: 2);

      await expectLater(
        repository.update(seat2.id, seatNumber: 'A1'),
        throwsA(isA<DuplicateSeatNumberException>()),
      );
    });

    test('delete — 좌석을 삭제한다', () async {
      final seat = await repository.create(seatNumber: 'A1', capacity: 4);
      await repository.delete(seat.id);

      final found = await repository.findById(seat.id);

      expect(found, isNull);
    });

    test('watchAll — 좌석 스트림을 반환한다', () async {
      await repository.create(seatNumber: 'A1', capacity: 4);

      final stream = repository.watchAll();
      final seats = await stream.first;

      expect(seats.length, 1);
    });
  });
}
