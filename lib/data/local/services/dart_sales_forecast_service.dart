import 'package:pos/domain/entities/daily_sales_report.dart';
import 'package:pos/domain/entities/sales_forecast.dart';
import 'package:pos/domain/repositories/i_sales_forecast_service.dart';

/// 순수 Dart 선형 회귀 기반 매출 예측 서비스.
///
/// 특성(feature): [bias, day_of_week_norm, prev_revenue_norm, rolling_avg_norm]
/// 학습: 경사하강법 1000회 반복
class DartSalesForecastService implements ISalesForecastService {
  static const _learningRate = 0.01;
  static const _iterations = 1000;
  static const _featureCount = 4;

  @override
  SalesForecast forecast(
    List<DailySalesReport> reports, {
    int forecastDays = 7,
  }) {
    if (reports.length < 7) return SalesForecast.empty();

    final sorted = List.of(reports)
      ..sort((a, b) => a.closedAt.compareTo(b.closedAt));

    final maxRevenue = sorted
        .map((r) => r.netRevenue)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    if (maxRevenue == 0) return SalesForecast.empty();

    final (xMatrix, yVector) = _buildTrainingData(sorted, maxRevenue);
    final weights = _trainGradientDescent(xMatrix, yVector);

    final predictions = _rollForward(
      sorted: sorted,
      weights: weights,
      maxRevenue: maxRevenue,
      forecastDays: forecastDays,
    );

    return SalesForecast(
      forecastDays: predictions,
      source: ForecastSource.dartRegression,
      trainedOnDays: sorted.length,
    );
  }

  (List<List<double>>, List<double>) _buildTrainingData(
    List<DailySalesReport> sorted,
    double maxRevenue,
  ) {
    final xMatrix = <List<double>>[];
    final yVector = <double>[];

    for (var i = 7; i < sorted.length; i++) {
      final r = sorted[i];
      final prev = sorted[i - 1];
      final rollingAvg = sorted
              .sublist(i - 7, i)
              .map((e) => e.netRevenue)
              .reduce((a, b) => a + b) /
          7.0;

      xMatrix.add([
        1.0,
        (r.closedAt.weekday - 1) / 6.0,
        prev.netRevenue / maxRevenue,
        rollingAvg / maxRevenue,
      ]);
      yVector.add(r.netRevenue / maxRevenue);
    }

    return (xMatrix, yVector);
  }

  List<double> _trainGradientDescent(
    List<List<double>> x,
    List<double> y,
  ) {
    final n = x.length;
    final weights = List<double>.filled(_featureCount, 0.0);

    for (var iter = 0; iter < _iterations; iter++) {
      final gradient = List<double>.filled(_featureCount, 0.0);

      for (var i = 0; i < n; i++) {
        final pred = _dot(weights, x[i]);
        final error = pred - y[i];
        for (var j = 0; j < _featureCount; j++) {
          gradient[j] += error * x[i][j];
        }
      }

      for (var j = 0; j < _featureCount; j++) {
        weights[j] -= _learningRate * gradient[j] / n;
      }
    }

    return weights;
  }

  List<ForecastDay> _rollForward({
    required List<DailySalesReport> sorted,
    required List<double> weights,
    required double maxRevenue,
    required int forecastDays,
  }) {
    final recentWindow = sorted.sublist(sorted.length - 7);
    final rollingBuffer =
        recentWindow.map((r) => r.netRevenue.toDouble()).toList();
    double prevRevenue = sorted.last.netRevenue.toDouble();
    DateTime nextDate = sorted.last.closedAt.add(const Duration(days: 1));

    final predictions = <ForecastDay>[];

    for (var i = 0; i < forecastDays; i++) {
      final rollingAvg =
          rollingBuffer.reduce((a, b) => a + b) / rollingBuffer.length;

      final features = [
        1.0,
        (nextDate.weekday - 1) / 6.0,
        prevRevenue / maxRevenue,
        rollingAvg / maxRevenue,
      ];

      final predictedNorm = _dot(weights, features).clamp(0.0, 1.5);
      final predicted = (predictedNorm * maxRevenue).round();

      predictions.add(ForecastDay(date: nextDate, predictedRevenue: predicted));

      rollingBuffer
        ..removeAt(0)
        ..add(predicted.toDouble());
      prevRevenue = predicted.toDouble();
      nextDate = nextDate.add(const Duration(days: 1));
    }

    return predictions;
  }

  double _dot(List<double> a, List<double> b) {
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      sum += a[i] * b[i];
    }
    return sum;
  }
}
