import 'package:pos/domain/entities/sales_analysis.dart';
import 'package:pos/domain/repositories/i_business_day_repository.dart';
import 'package:pos/domain/repositories/i_sales_analysis_service.dart';

class GetSalesAnalysisUseCase {
  GetSalesAnalysisUseCase({
    required this.businessDayRepository,
    required this.salesAnalysisService,
  });

  final IBusinessDayRepository businessDayRepository;
  final ISalesAnalysisService salesAnalysisService;

  Future<SalesAnalysis> execute({int days = 30}) async {
    final to = DateTime.now();
    final from = to.subtract(Duration(days: days));
    final reports = await businessDayRepository.getReports(from: from, to: to);
    return salesAnalysisService.analyze(reports);
  }
}
