import 'package:pos/domain/exceptions/domain_exceptions.dart';

/// domain exception을 사용자에게 보여줄 한국어 메시지로 변환한다.
String mapToUserMessage(Object error) {
  return switch (error) {
    BusinessDayNotFoundException() =>
      '영업을 시작한 후 주문을 생성할 수 있습니다.\n홈 화면에서 영업 시작을 눌러주세요.',
    BusinessDayAlreadyOpenException() =>
      '이미 열린 영업일이 있습니다. 기존 영업을 마감한 후 새 영업을 시작하세요.',
    InvalidStateTransitionException() =>
      '현재 상태에서는 해당 작업을 수행할 수 없습니다.',
    OrderNotModifiableException() => '전달 완료된 주문은 수정할 수 없습니다.',
    PendingOrdersExistException() =>
      '처리 중인 주문이 있어 마감할 수 없습니다. 주문을 완료하거나 취소한 후 다시 시도하세요.',
    CreditAccountHasBalanceException() =>
      '미납 잔액이 남아 있는 외상 계좌는 삭제할 수 없습니다.',
    MenuItemInUseException() =>
      '진행 중인 주문에서 사용 중인 메뉴는 삭제할 수 없습니다.',
    SeatInUseException() =>
      '진행 중인 주문이 연결된 좌석은 삭제할 수 없습니다.',
    DuplicateSeatNumberException() =>
      '이미 사용 중인 좌석 번호입니다. 다른 번호를 입력하세요.',
    MenuItemNotFoundException() => '메뉴를 찾을 수 없습니다.',
    SeatNotFoundException() => '좌석을 찾을 수 없습니다.',
    OrderNotFoundException() => '주문을 찾을 수 없습니다.',
    OrderItemNotFoundException() => '주문 항목을 찾을 수 없습니다.',
    CreditAccountNotFoundException() => '외상 계좌를 찾을 수 없습니다.',
    _ => '오류가 발생했습니다. 앱을 다시 시작해 주세요.',
  };
}
