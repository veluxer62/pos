import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pos/domain/entities/credit_transaction.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';
import 'package:pos/domain/repositories/i_credit_account_repository.dart';
import 'package:pos/domain/usecases/credit/pay_credit_account_use_case.dart';
import 'package:pos/domain/value_objects/credit_transaction_type.dart';

import 'pay_credit_account_use_case_test.mocks.dart';

@GenerateMocks([ICreditAccountRepository])
void main() {
  late MockICreditAccountRepository mockRepo;
  late PayCreditAccountUseCase sut;

  final now = DateTime(2024);

  CreditTransaction makeTransaction({
    int amount = 5000,
    CreditTransactionType type = CreditTransactionType.payment,
  }) =>
      CreditTransaction(
        id: 'tx-1',
        creditAccountId: 'acc-1',
        type: type,
        amount: amount,
        createdAt: now,
      );

  setUp(() {
    mockRepo = MockICreditAccountRepository();
    sut = PayCreditAccountUseCase(repository: mockRepo);
  });

  group('PayCreditAccountUseCase', () {
    test('정상 납부 시 PaymentResult를 반환한다', () async {
      final result = PaymentResult(
        transaction: makeTransaction(amount: 5000),
        previousBalance: 10000,
        appliedAmount: 5000,
        newBalance: 5000,
      );
      when(mockRepo.pay(accountId: 'acc-1', amount: 5000))
          .thenAnswer((_) async => result);

      final res = await sut.execute(accountId: 'acc-1', amount: 5000);

      expect(res.newBalance, 5000);
      expect(res.appliedAmount, 5000);
      expect(res.overpaidAmount, isNull);
      verify(mockRepo.pay(accountId: 'acc-1', amount: 5000)).called(1);
    });

    test('과납 시 overpaidAmount가 설정되고 잔액은 0이 된다', () async {
      final result = PaymentResult(
        transaction: makeTransaction(amount: 10000),
        previousBalance: 7000,
        appliedAmount: 7000,
        newBalance: 0,
        overpaidAmount: 3000,
      );
      when(mockRepo.pay(accountId: 'acc-1', amount: 10000))
          .thenAnswer((_) async => result);

      final res = await sut.execute(accountId: 'acc-1', amount: 10000);

      expect(res.newBalance, 0);
      expect(res.overpaidAmount, 3000);
    });

    test('존재하지 않는 계좌이면 CreditAccountNotFoundException을 전파한다', () async {
      when(mockRepo.pay(accountId: 'none', amount: 1000))
          .thenThrow(const CreditAccountNotFoundException('none'));

      await expectLater(
        sut.execute(accountId: 'none', amount: 1000),
        throwsA(isA<CreditAccountNotFoundException>()),
      );
    });
  });
}
