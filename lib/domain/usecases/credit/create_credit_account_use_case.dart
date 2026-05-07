import 'package:pos/domain/entities/credit_account.dart';
import 'package:pos/domain/repositories/i_credit_account_repository.dart';

class CreateCreditAccountUseCase {
  CreateCreditAccountUseCase({required this.repository});

  final ICreditAccountRepository repository;

  Future<CreditAccount> execute(
    String customerName, {
    String? phone,
    String? note,
  }) async =>
      repository.create(customerName, phone: phone, note: note);
}
