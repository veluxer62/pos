import 'package:pos/data/local/daos/business_day_dao.dart';
import 'package:pos/data/local/database/app_database.dart';
import 'package:pos/domain/entities/business_day.dart';
import 'package:pos/domain/entities/daily_sales_report.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';
import 'package:pos/domain/repositories/i_business_day_repository.dart';
import 'package:pos/domain/value_objects/business_day_status.dart';
import 'package:uuid/uuid.dart';

class LocalBusinessDayRepository implements IBusinessDayRepository {
  LocalBusinessDayRepository(this._dao);

  final BusinessDayDao _dao;
  final _uuid = const Uuid();

  @override
  Future<BusinessDay?> getOpen() => _dao.getOpen();

  @override
  Future<BusinessDay> open() async {
    final existing = await _dao.getOpen();
    if (existing != null) throw const BusinessDayAlreadyOpenException();

    final now = DateTime.now();
    return _dao.insert(
      BusinessDaysCompanion.insert(
        id: _uuid.v4(),
        status: BusinessDayStatus.open,
        openedAt: now,
        createdAt: now,
      ),
    );
  }

  @override
  Future<CloseResult> close({bool forceClose = false}) {
    // Phase 6에서 AppDatabase 직접 주입 후 transaction() 블록으로 구현
    throw UnimplementedError('Phase 6에서 구현');
  }

  @override
  Future<BusinessDay?> findById(String id) => _dao.findById(id);

  @override
  Future<List<BusinessDay>> findAll({
    DateTime? from,
    DateTime? to,
    int limit = 30,
    int offset = 0,
  }) =>
      _dao.findAll(from: from, to: to, limit: limit, offset: offset);

  @override
  Future<DailySalesReport?> getReport(String businessDayId) {
    // Phase 6에서 구현
    throw UnimplementedError('Phase 6에서 구현');
  }

  @override
  Future<List<DailySalesReport>> getReports({
    required DateTime from,
    required DateTime to,
  }) {
    // Phase 6에서 구현
    throw UnimplementedError('Phase 6에서 구현');
  }

  @override
  Stream<BusinessDay?> watchOpen() => _dao.watchOpen();
}
