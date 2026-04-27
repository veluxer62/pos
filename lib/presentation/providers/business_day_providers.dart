import 'package:pos/core/di/providers.dart';
import 'package:pos/domain/entities/business_day.dart';
import 'package:pos/domain/entities/daily_sales_report.dart';
import 'package:pos/domain/usecases/business_day/close_business_day_use_case.dart';
import 'package:pos/domain/usecases/business_day/open_business_day_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'business_day_providers.g.dart';

@riverpod
OpenBusinessDayUseCase openBusinessDayUseCase(Ref ref) =>
    OpenBusinessDayUseCase(
      repository: ref.watch(businessDayRepositoryProvider),
    );

@riverpod
CloseBusinessDayUseCase closeBusinessDayUseCase(Ref ref) =>
    CloseBusinessDayUseCase(
      repository: ref.watch(businessDayRepositoryProvider),
    );

@riverpod
Stream<BusinessDay?> openBusinessDay(Ref ref) =>
    ref.watch(businessDayRepositoryProvider).watchOpen();

@riverpod
Future<DailySalesReport?> businessDayReport(Ref ref, String businessDayId) =>
    ref.watch(businessDayRepositoryProvider).getReport(businessDayId);

@riverpod
Future<List<BusinessDay>> businessDayHistory(
  Ref ref, {
  int limit = 30,
  int offset = 0,
}) =>
    ref.watch(businessDayRepositoryProvider).findAll(
          limit: limit,
          offset: offset,
        );
