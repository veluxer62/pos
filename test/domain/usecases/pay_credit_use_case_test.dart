import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pos/domain/entities/credit_transaction.dart';
import 'package:pos/domain/entities/order.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';
import 'package:pos/domain/repositories/i_credit_account_repository.dart';
import 'package:pos/domain/repositories/i_order_repository.dart';
import 'package:pos/domain/usecases/order/pay_credit_use_case.dart';
import 'package:pos/domain/value_objects/credit_transaction_type.dart';
import 'package:pos/domain/value_objects/order_status.dart';

import 'pay_credit_use_case_test.mocks.dart';

@GenerateMocks([IOrderRepository, ICreditAccountRepository])
void main() {
  late MockIOrderRepository mockOrderRepo;
  late MockICreditAccountRepository mockCreditRepo;
  late PayCreditUseCase sut;

  final deliveredOrder = Order(
    id: 'order-1',
    businessDayId: 'bd-1',
    seatId: 'seat-1',
    status: const OrderStatusDelivered(),
    totalAmount: 10000,
    orderedAt: DateTime(2024),
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    deliveredAt: DateTime(2024),
  );

  final creditedOrder = deliveredOrder.copyWith(
    status: const OrderStatusCredited(),
    creditedAt: DateTime(2024),
    creditAccountId: 'account-1',
  );

  final mockTransaction = CreditTransaction(
    id: 'tx-1',
    creditAccountId: 'account-1',
    orderId: 'order-1',
    amount: 10000,
    type: CreditTransactionType.charge,
    createdAt: DateTime(2024),
  );

  setUp(() {
    mockOrderRepo = MockIOrderRepository();
    mockCreditRepo = MockICreditAccountRepository();
    sut = PayCreditUseCase(
      orderRepository: mockOrderRepo,
      creditAccountRepository: mockCreditRepo,
    );
  });

  group('PayCreditUseCase', () {
    test('DELIVERED 주문을 CREDITED로 전환하고 외상 계좌에 charge한다', () async {
      when(mockOrderRepo.findById('order-1'))
          .thenAnswer((_) async => deliveredOrder);
      when(
        mockCreditRepo.charge(
          accountId: 'account-1',
          orderId: 'order-1',
          amount: 10000,
        ),
      ).thenAnswer((_) async => mockTransaction);
      when(mockOrderRepo.payCredit('order-1', 'account-1'))
          .thenAnswer((_) async => creditedOrder);

      final result = await sut.execute('order-1', 'account-1');

      expect(result.status, isA<OrderStatusCredited>());
      expect(result.creditedAt, isNotNull);
      expect(result.creditAccountId, 'account-1');
      verify(
        mockCreditRepo.charge(
          accountId: 'account-1',
          orderId: 'order-1',
          amount: 10000,
        ),
      ).called(1);
      verify(mockOrderRepo.payCredit('order-1', 'account-1')).called(1);
    });

    test('주문을 찾을 수 없으면 OrderNotFoundException을 던진다', () async {
      when(mockOrderRepo.findById('order-1')).thenAnswer((_) async => null);

      await expectLater(
        sut.execute('order-1', 'account-1'),
        throwsA(isA<OrderNotFoundException>()),
      );
    });

    test('잘못된 상태 전이 시 InvalidStateTransitionException을 전파한다', () async {
      when(mockOrderRepo.findById('order-1'))
          .thenAnswer((_) async => deliveredOrder);
      when(
        mockCreditRepo.charge(
          accountId: 'account-1',
          orderId: 'order-1',
          amount: 10000,
        ),
      ).thenAnswer((_) async => mockTransaction);
      when(mockOrderRepo.payCredit('order-1', 'account-1')).thenThrow(
        const InvalidStateTransitionException(from: 'pending', to: 'credited'),
      );

      await expectLater(
        sut.execute('order-1', 'account-1'),
        throwsA(isA<InvalidStateTransitionException>()),
      );
    });
  });
}
