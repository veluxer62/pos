import 'package:pos/core/di/providers.dart';
import 'package:pos/domain/entities/credit_account.dart';
import 'package:pos/domain/entities/credit_transaction.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'credit_account_providers.g.dart';

@riverpod
Future<List<CreditAccount>> creditAccountList(
  Ref ref, {
  bool? hasBalance,
}) =>
    ref.watch(creditAccountRepositoryProvider).findAll(hasBalance: hasBalance);

@riverpod
Future<CreditAccount?> creditAccountDetail(Ref ref, String id) =>
    ref.watch(creditAccountRepositoryProvider).findById(id);

@riverpod
Stream<List<CreditAccount>> creditAccountStream(Ref ref) =>
    ref.watch(creditAccountRepositoryProvider).watchAll();

@riverpod
Future<List<CreditTransaction>> creditTransactionList(
  Ref ref,
  String accountId, {
  int limit = 50,
  int offset = 0,
}) =>
    ref.watch(creditAccountRepositoryProvider).getTransactions(
          accountId,
          limit: limit,
          offset: offset,
        );
