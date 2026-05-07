import 'package:flutter_test/flutter_test.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';
import 'package:pos/presentation/utils/error_message_mapper.dart';

void main() {
  group('mapToUserMessage', () {
    test('BusinessDayNotFoundException → 영업 시작 안내 메시지 반환', () {
      const error = BusinessDayNotFoundException();
      expect(
        mapToUserMessage(error),
        '영업을 시작한 후 주문을 생성할 수 있습니다.\n홈 화면에서 영업 시작을 눌러주세요.',
      );
    });

    test('BusinessDayAlreadyOpenException → 이미 열린 영업일 메시지 반환', () {
      const error = BusinessDayAlreadyOpenException();
      expect(
        mapToUserMessage(error),
        '이미 열린 영업일이 있습니다. 기존 영업을 마감한 후 새 영업을 시작하세요.',
      );
    });

    test('InvalidStateTransitionException → 상태 전이 불가 메시지 반환', () {
      const error = InvalidStateTransitionException(from: 'cancelled', to: 'delivered');
      expect(
        mapToUserMessage(error),
        '현재 상태에서는 해당 작업을 수행할 수 없습니다.',
      );
    });

    test('OrderNotModifiableException → 수정 불가 메시지 반환', () {
      const error = OrderNotModifiableException();
      expect(mapToUserMessage(error), '전달 완료된 주문은 수정할 수 없습니다.');
    });

    test('PendingOrdersExistException → 미처리 주문 존재 메시지 반환', () {
      const error = PendingOrdersExistException(pendingCount: 1, deliveredCount: 0);
      expect(
        mapToUserMessage(error),
        '처리 중인 주문이 있어 마감할 수 없습니다. 주문을 완료하거나 취소한 후 다시 시도하세요.',
      );
    });

    test('CreditAccountHasBalanceException → 미납 잔액 메시지 반환', () {
      const error = CreditAccountHasBalanceException(balance: 10000);
      expect(
        mapToUserMessage(error),
        '미납 잔액이 남아 있는 외상 계좌는 삭제할 수 없습니다.',
      );
    });

    test('MenuItemInUseException → 메뉴 사용 중 메시지 반환', () {
      const error = MenuItemInUseException();
      expect(mapToUserMessage(error), '진행 중인 주문에서 사용 중인 메뉴는 삭제할 수 없습니다.');
    });

    test('SeatInUseException → 좌석 사용 중 메시지 반환', () {
      const error = SeatInUseException();
      expect(mapToUserMessage(error), '진행 중인 주문이 연결된 좌석은 삭제할 수 없습니다.');
    });

    test('DuplicateSeatNumberException → 중복 좌석 번호 메시지 반환', () {
      const error = DuplicateSeatNumberException('A1');
      expect(mapToUserMessage(error), '이미 사용 중인 좌석 번호입니다. 다른 번호를 입력하세요.');
    });

    test('MenuItemNotFoundException → 메뉴 없음 메시지 반환', () {
      const error = MenuItemNotFoundException('id-123');
      expect(mapToUserMessage(error), '메뉴를 찾을 수 없습니다.');
    });

    test('SeatNotFoundException → 좌석 없음 메시지 반환', () {
      const error = SeatNotFoundException('id-456');
      expect(mapToUserMessage(error), '좌석을 찾을 수 없습니다.');
    });

    test('OrderNotFoundException → 주문 없음 메시지 반환', () {
      const error = OrderNotFoundException('id-789');
      expect(mapToUserMessage(error), '주문을 찾을 수 없습니다.');
    });

    test('OrderItemNotFoundException → 주문 항목 없음 메시지 반환', () {
      const error = OrderItemNotFoundException('id-000');
      expect(mapToUserMessage(error), '주문 항목을 찾을 수 없습니다.');
    });

    test('CreditAccountNotFoundException → 외상 계좌 없음 메시지 반환', () {
      const error = CreditAccountNotFoundException('id-111');
      expect(mapToUserMessage(error), '외상 계좌를 찾을 수 없습니다.');
    });

    test('알 수 없는 exception → 기본 오류 메시지 반환', () {
      expect(
        mapToUserMessage(Exception('알 수 없는 오류')),
        '오류가 발생했습니다. 앱을 다시 시작해 주세요.',
      );
    });

    test('일반 Error → 기본 오류 메시지 반환', () {
      expect(
        mapToUserMessage(StateError('unexpected state')),
        '오류가 발생했습니다. 앱을 다시 시작해 주세요.',
      );
    });
  });
}
