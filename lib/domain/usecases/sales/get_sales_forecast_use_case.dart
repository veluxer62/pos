import 'package:pos/domain/entities/sales_forecast.dart';
import 'package:pos/domain/repositories/i_business_day_repository.dart';
import 'package:pos/domain/repositories/i_sales_forecast_service.dart';

class GetSalesForecastUseCase {
  GetSalesForecastUseCase({
    required this.businessDayRepository,
    required this.salesForecastService,
  });

  final IBusinessDayRepository businessDayRepository;
  final ISalesForecastService salesForecastService;

  Future<SalesForecast> execute({
    int trainingDays = 60,
    int forecastDays = 7,
  }) async {
    final to = DateTime.now();
    final from = to.subtract(Duration(days: trainingDays));
    final reports = await businessDayRepository.getReports(from: from, to: to);
    return salesForecastService.forecast(reports, forecastDays: forecastDays);
  }
}
