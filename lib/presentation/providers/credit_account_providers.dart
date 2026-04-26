import 'package:pos/core/di/providers.dart';
import 'package:pos/domain/entities/credit_account.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'credit_account_providers.g.dart';

@riverpod
Future<List<CreditAccount>> creditAccountList(
  Ref ref, {
  bool? hasBalance,
}) =>
    ref.watch(creditAccountRepositoryProvider).findAll(hasBalance: hasBalance);
