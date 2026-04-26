import 'package:drift/drift.dart';
import 'package:pos/data/local/daos/seat_dao.dart';
import 'package:pos/data/local/database/app_database.dart';
import 'package:pos/domain/entities/seat.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';
import 'package:pos/domain/repositories/i_seat_repository.dart';
import 'package:uuid/uuid.dart';

class LocalSeatRepository implements ISeatRepository {
  LocalSeatRepository(this._dao);

  final SeatDao _dao;
  final _uuid = const Uuid();

  @override
  Future<List<Seat>> findAll() => _dao.findAll();

  @override
  Future<Seat?> findById(String id) => _dao.findById(id);

  @override
  Future<Seat?> findBySeatNumber(String seatNumber) =>
      _dao.findBySeatNumber(seatNumber);

  @override
  Future<Seat> create({
    required String seatNumber,
    required int capacity,
  }) async {
    final existing = await _dao.findBySeatNumber(seatNumber);
    if (existing != null) {
      throw DuplicateSeatNumberException(seatNumber);
    }

    final now = DateTime.now();
    return _dao.insert(
      SeatsCompanion.insert(
        id: _uuid.v4(),
        seatNumber: seatNumber,
        capacity: capacity,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<Seat> update(
    String id, {
    String? seatNumber,
    int? capacity,
  }) async {
    final existing = await _dao.findById(id);
    if (existing == null) throw SeatNotFoundException(id);

    if (seatNumber != null) {
      final duplicate = await _dao.findBySeatNumber(seatNumber);
      if (duplicate != null && duplicate.id != id) {
        throw DuplicateSeatNumberException(seatNumber);
      }
    }

    final now = DateTime.now();
    return _dao.updateRow(
      id,
      SeatsCompanion(
        seatNumber: seatNumber != null ? Value(seatNumber) : const Value.absent(),
        capacity: capacity != null ? Value(capacity) : const Value.absent(),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> delete(String id) => _dao.deleteRow(id);

  @override
  Stream<List<Seat>> watchAll() => _dao.watchAll();
}
