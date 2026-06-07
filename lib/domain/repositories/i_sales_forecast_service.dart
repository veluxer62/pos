import 'package:pos/domain/entities/daily_sales_report.dart';
import 'package:pos/domain/entities/sales_forecast.dart';

abstract interface class ISalesForecastService {
  /// [reports]로 모델을 학습한 뒤 다음 [forecastDays]일의 매출을 예측한다.
  SalesForecast forecast(
    List<DailySalesReport> reports, {
    int forecastDays = 7,
  });
}
