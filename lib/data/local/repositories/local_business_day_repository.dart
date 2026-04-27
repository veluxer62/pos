import 'package:pos/data/local/daos/business_day_dao.dart';
import 'package:pos/domain/entities/business_day.dart';
import 'package:pos/domain/entities/daily_sales_report.dart';
import 'package:pos/domain/repositories/i_business_day_repository.dart';

class LocalBusinessDayRepository implements IBusinessDayRepository {
  LocalBusinessDayRepository(this._dao);

  final BusinessDayDao _dao;

  @override
  Future<BusinessDay?> getOpen() => _dao.getOpen();

  @override
  Future<BusinessDay> open() => _dao.open();

  @override
  Future<CloseResult> close({bool forceClose = false}) =>
      _dao.closeBusinessDay(forceClose: forceClose);

  @override
  Future<BusinessDay?> findById(String id) => _dao.findById(id);

  @override
  Future<List<BusinessDay>> findAll({
    DateTime? from,
    DateTime? to,
    int limit = 30,
    int offset = 0,
  }) => _dao.findAll(from: from, to: to, limit: limit, offset: offset);

  @override
  Future<DailySalesReport?> getReport(String businessDayId) =>
      _dao.getReport(businessDayId);

  @override
  Future<List<DailySalesReport>> getReports({
    required DateTime from,
    required DateTime to,
  }) => _dao.getReports(from: from, to: to);

  @override
  Stream<BusinessDay?> watchOpen() => _dao.watchOpen();
}
