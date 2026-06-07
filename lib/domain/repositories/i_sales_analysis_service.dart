import 'package:pos/domain/entities/daily_sales_report.dart';
import 'package:pos/domain/entities/sales_analysis.dart';

abstract interface class ISalesAnalysisService {
  SalesAnalysis analyze(List<DailySalesReport> reports);
}
