import 'package:pos/core/di/providers.dart';
import 'package:pos/domain/entities/sales_forecast.dart';
import 'package:pos/domain/usecases/sales/get_sales_forecast_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sales_forecast_providers.g.dart';

@riverpod
GetSalesForecastUseCase getSalesForecastUseCase(Ref ref) =>
    GetSalesForecastUseCase(
      businessDayRepository: ref.watch(businessDayRepositoryProvider),
      salesForecastService: ref.watch(salesForecastServiceProvider),
    );

@riverpod
Future<SalesForecast> salesForecast(Ref ref) =>
    ref.watch(getSalesForecastUseCaseProvider).execute();
