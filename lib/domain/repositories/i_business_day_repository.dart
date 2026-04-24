import 'package:pos/domain/entities/business_day.dart';
import 'package:pos/domain/entities/daily_sales_report.dart';
import 'package:pos/domain/value_objects/close_result.dart';

export 'package:pos/domain/value_objects/close_result.dart';

abstract interface class IBusinessDayRepository {
  /// OPEN 영업일이 이미 존재하면 [BusinessDayAlreadyOpenException].
  Future<BusinessDay> open();

  /// 현재 OPEN 영업일. 없으면 null.
  Future<BusinessDay?> getOpen();

  /// 마감 + DailySalesReport 생성은 동일 트랜잭션 내 원자적 수행.
  /// forceClose=false 시 미처리 주문 존재하면 [PendingOrdersExistException].
  Future<CloseResult> close({bool forceClose = false});
  Future<BusinessDay?> findById(String id);

  /// 날짜 역순 정렬.
  Future<List<BusinessDay>> findAll({
    DateTime? from,
    DateTime? to,
    int limit = 30,
    int offset = 0,
  });
  Future<DailySalesReport?> getReport(String businessDayId);
  Future<List<DailySalesReport>> getReports({
    required DateTime from,
    required DateTime to,
  });
  Stream<BusinessDay?> watchOpen();
}
