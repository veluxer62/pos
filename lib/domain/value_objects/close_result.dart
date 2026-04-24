import 'package:pos/domain/entities/business_day.dart';
import 'package:pos/domain/entities/daily_sales_report.dart';

class CloseResult {
  const CloseResult({
    required this.businessDay,
    required this.report,
  });

  final BusinessDay businessDay;
  final DailySalesReport report;
}
