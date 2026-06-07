import 'package:pos/core/di/providers.dart';
import 'package:pos/domain/entities/sales_analysis.dart';
import 'package:pos/domain/usecases/sales/get_sales_analysis_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sales_analysis_providers.g.dart';

@riverpod
GetSalesAnalysisUseCase getSalesAnalysisUseCase(Ref ref) =>
    GetSalesAnalysisUseCase(
      businessDayRepository: ref.watch(businessDayRepositoryProvider),
      salesAnalysisService: ref.watch(salesAnalysisServiceProvider),
    );

@riverpod
Future<SalesAnalysis> salesAnalysis(Ref ref, {int days = 30}) =>
    ref.watch(getSalesAnalysisUseCaseProvider).execute(days: days);
