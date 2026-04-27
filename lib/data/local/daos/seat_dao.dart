import 'package:drift/drift.dart';
import 'package:pos/data/local/database/app_database.dart';
import 'package:pos/data/local/database/tables.dart';
import 'package:pos/domain/entities/seat.dart';

part 'seat_dao.g.dart';

@DriftAccessor(tables: [Seats])
class SeatDao extends DatabaseAccessor<AppDatabase> with _$SeatDaoMixin {
  SeatDao(super.db);

  Future<List<Seat>> findAll() async {
    final query = select(seats)
      ..orderBy([(t) => OrderingTerm.asc(t.seatNumber)]);
    final rows = await query.get();
    return rows.map(_toEntity).toList();
  }

  Future<Seat?> findById(String id) async {
    final row =
        await (select(seats)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  Future<Seat?> findBySeatNumber(String seatNumber) async {
    final row = await (select(seats)
          ..where((t) => t.seatNumber.equals(seatNumber)))
        .getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  Future<Seat> insert(SeatsCompanion companion) async {
    await into(seats).insert(companion);
    final row = await (select(seats)
          ..where((t) => t.id.equals(companion.id.value)))
        .getSingle();
    return _toEntity(row);
  }

  Future<Seat> updateRow(String id, SeatsCompanion companion) async {
    await (update(seats)..where((t) => t.id.equals(id))).write(companion);
    final row =
        await (select(seats)..where((t) => t.id.equals(id))).getSingle();
    return _toEntity(row);
  }

  Future<void> deleteRow(String id) async {
    await (delete(seats)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<Seat>> watchAll() {
    return (select(seats)..orderBy([(t) => OrderingTerm.asc(t.seatNumber)]))
        .watch()
        .map((rows) => rows.map(_toEntity).toList());
  }

  Seat _toEntity(SeatRow row) => Seat(
        id: row.id,
        seatNumber: row.seatNumber,
        capacity: row.capacity,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );
}
