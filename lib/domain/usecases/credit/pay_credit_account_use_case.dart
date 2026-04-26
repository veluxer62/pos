import 'package:pos/domain/repositories/i_credit_account_repository.dart';

class PayCreditAccountUseCase {
  PayCreditAccountUseCase({required this.repository});

  final ICreditAccountRepository repository;

  Future<PaymentResult> execute({
    required String accountId,
    required int amount,
    String? note,
  }) async => repository.pay(accountId: accountId, amount: amount, note: note);
}
