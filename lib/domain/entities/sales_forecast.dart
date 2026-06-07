class ForecastDay {
  const ForecastDay({
    required this.date,
    required this.predictedRevenue,
  });

  final DateTime date;

  /// 예측 순매출 (KRW)
  final int predictedRevenue;
}

enum ForecastSource { dartRegression, tflite }

class SalesForecast {
  const SalesForecast({
    required this.forecastDays,
    required this.source,
    required this.trainedOnDays,
  });

  final List<ForecastDay> forecastDays;
  final ForecastSource source;

  /// 학습에 사용된 영업일 수
  final int trainedOnDays;

  bool get isReliable => trainedOnDays >= 14;

  static SalesForecast empty() => const SalesForecast(
        forecastDays: [],
        source: ForecastSource.dartRegression,
        trainedOnDays: 0,
      );
}
