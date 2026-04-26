import 'package:drift/drift.dart';
import 'package:pos/data/local/database/app_database.dart';
import 'package:pos/data/local/database/tables.dart';
import 'package:pos/domain/entities/business_day.dart';
import 'package:pos/domain/value_objects/business_day_status.dart';

part 'business_day_dao.g.dart';

@DriftAccessor(tables: [BusinessDays])
class BusinessDayDao extends DatabaseAccessor<AppDatabase>
    with _$BusinessDayDaoMixin {
  BusinessDayDao(super.db);

  Future<BusinessDay?> getOpen() async {
    final row = await (select(businessDays)
          ..where((t) => t.status.equals(BusinessDayStatus.open.name))
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  Future<BusinessDay?> findById(String id) async {
    final row = await (select(businessDays)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  Future<BusinessDay> insert(BusinessDaysCompanion companion) async {
    await into(businessDays).insert(companion);
    final row = await (select(businessDays)
          ..where((t) => t.id.equals(companion.id.value)))
        .getSingle();
    return _toEntity(row);
  }

  Future<BusinessDay> updateRow(
    String id,
    BusinessDaysCompanion companion,
  ) async {
    await (update(businessDays)..where((t) => t.id.equals(id))).write(companion);
    final row = await (select(businessDays)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    return _toEntity(row);
  }

  Stream<BusinessDay?> watchOpen() {
    return (select(businessDays)
          ..where((t) => t.status.equals(BusinessDayStatus.open.name)))
        .watchSingleOrNull()
        .map((row) => row == null ? null : _toEntity(row));
  }

  Future<List<BusinessDay>> findAll({
    DateTime? from,
    DateTime? to,
    int limit = 30,
    int offset = 0,
  }) async {
    final query = select(businessDays)
      ..orderBy([(t) => OrderingTerm.desc(t.openedAt)])
      ..limit(limit, offset: offset);

    if (from != null) {
      query.where((t) => t.openedAt.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      query.where((t) => t.openedAt.isSmallerOrEqualValue(to));
    }

    final rows = await query.get();
    return rows.map(_toEntity).toList();
  }

  BusinessDay _toEntity(BusinessDayRow row) => BusinessDay(
        id: row.id,
        status: row.status,
        openedAt: row.openedAt,
        createdAt: row.createdAt,
        closedAt: row.closedAt,
      );
}
