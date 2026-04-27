import 'package:pos/core/di/providers.dart';
import 'package:pos/domain/entities/business_day.dart';
import 'package:pos/domain/entities/daily_sales_report.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'business_day_providers.g.dart';

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
