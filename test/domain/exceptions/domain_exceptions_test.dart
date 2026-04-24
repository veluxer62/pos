import 'package:flutter_test/flutter_test.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';

void main() {
  group('DomainException toString', () {
    test('runtimeType과 message를 포함', () {
      const e = BusinessDayNotFoundException();
      expect(e.toString(), contains('BusinessDayNotFoundException'));
      expect(e.toString(), contains(e.message));
    });
  });

  group('InvalidStateTransitionException', () {
    const e = InvalidStateTransitionException(from: 'pending', to: 'cancelled');

    test('from·to 필드 저장', () {
      expect(e.from, equals('pending'));
      expect(e.to, equals('cancelled'));
    });

    test('message에 from·to 포함', () {
      expect(e.message, contains('pending'));
      expect(e.message, contains('cancelled'));
    });
  });

  group('DuplicateSeatNumberException', () {
    const e = DuplicateSeatNumberException('A1');

    test('seatNumber 필드 저장', () {
      expect(e.seatNumber, equals('A1'));
    });

    test('message에 seatNumber 포함', () {
      expect(e.message, contains('A1'));
    });
  });

  group('나머지 예외 message 검증', () {
    test('BusinessDayNotFoundException', () {
      expect(
        const BusinessDayNotFoundException().message,
        isNotEmpty,
      );
    });

    test('BusinessDayAlreadyOpenException', () {
      expect(
        const BusinessDayAlreadyOpenException().message,
        isNotEmpty,
      );
    });

    test('OrderNotModifiableException', () {
      expect(
        const OrderNotModifiableException().message,
        isNotEmpty,
      );
    });

    test('PendingOrdersExistException', () {
      const e = PendingOrdersExistException(pendingCount: 2, deliveredCount: 1);
      expect(e.message, isNotEmpty);
      expect(e.pendingCount, equals(2));
      expect(e.deliveredCount, equals(1));
    });

    test('CreditAccountHasBalanceException', () {
      const e = CreditAccountHasBalanceException(balance: 15000);
      expect(e.message, isNotEmpty);
      expect(e.balance, equals(15000));
    });

    test('MenuItemInUseException', () {
      expect(
        const MenuItemInUseException().message,
        isNotEmpty,
      );
    });

    test('SeatInUseException', () {
      expect(
        const SeatInUseException().message,
        isNotEmpty,
      );
    });
  });
}
