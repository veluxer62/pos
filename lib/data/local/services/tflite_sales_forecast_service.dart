import 'package:pos/domain/entities/daily_sales_report.dart';
import 'package:pos/domain/entities/sales_forecast.dart';
import 'package:pos/domain/repositories/i_sales_forecast_service.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// TFLite 모델 기반 매출 예측 서비스.
///
/// 모델 파일: assets/models/sales_forecast.tflite
/// 학습 스크립트: scripts/train_sales_model.py
///
/// 모델이 없으면 [ModelNotLoadedException]을 던진다.
/// DI에서 [DartSalesForecastService]와 교체하여 사용.
class TFLiteSalesForecastService implements ISalesForecastService {
  static const _modelAssetPath = 'assets/models/sales_forecast.tflite';

  Interpreter? _interpreter;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(_modelAssetPath);
    } on Exception catch (e) {
      throw ModelNotLoadedException(_modelAssetPath, e);
    }
  }

  @override
  SalesForecast forecast(
    List<DailySalesReport> reports, {
    int forecastDays = 7,
  }) {
    final interpreter = _interpreter;
    if (interpreter == null) throw const ModelNotLoadedException._noModel();
    if (reports.length < 7) return SalesForecast.empty();

    final sorted = List.of(reports)
      ..sort((a, b) => a.closedAt.compareTo(b.closedAt));

    final maxRevenue = sorted
        .map((r) => r.netRevenue)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    if (maxRevenue == 0) return SalesForecast.empty();

    final recentWindow =
        sorted.sublist(sorted.length - 7).map((r) => r.netRevenue.toDouble()).toList();
    double prevRevenue = sorted.last.netRevenue.toDouble();
    DateTime nextDate = sorted.last.closedAt.add(const Duration(days: 1));

    final predictions = <ForecastDay>[];

    for (var i = 0; i < forecastDays; i++) {
      final rollingAvg =
          recentWindow.reduce((a, b) => a + b) / recentWindow.length;

      final input = [
        [
          (nextDate.weekday - 1) / 6.0,
          prevRevenue / maxRevenue,
          rollingAvg / maxRevenue,
        ],
      ];
      final output = List.filled(1, [0.0]);

      interpreter.run(input, output);

      final predictedNorm = (output[0][0] as num).toDouble().clamp(0.0, 1.5);
      final predicted = (predictedNorm * maxRevenue).round();

      predictions.add(ForecastDay(date: nextDate, predictedRevenue: predicted));

      recentWindow
        ..removeAt(0)
        ..add(predicted.toDouble());
      prevRevenue = predicted.toDouble();
      nextDate = nextDate.add(const Duration(days: 1));
    }

    return SalesForecast(
      forecastDays: predictions,
      source: ForecastSource.tflite,
      trainedOnDays: sorted.length,
    );
  }

  void dispose() => _interpreter?.close();
}

class ModelNotLoadedException implements Exception {
  const ModelNotLoadedException(this.assetPath, [this.cause]);
  const ModelNotLoadedException._noModel()
      : assetPath = TFLiteSalesForecastService._modelAssetPath,
        cause = null;

  final String assetPath;
  final Object? cause;

  @override
  String toString() =>
      'ModelNotLoadedException: $assetPath を読み込めませんでした。'
      'scripts/train_sales_model.py を実行してモデルを生成してください。';
}
