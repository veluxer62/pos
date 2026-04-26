sealed class DomainException implements Exception {
  const DomainException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// OPEN 상태의 영업일이 없을 때 — 주문 생성·상태 변경 시 UseCase가 선행 확인
final class BusinessDayNotFoundException extends DomainException {
  const BusinessDayNotFoundException()
      : super('영업일이 열려 있지 않습니다. 영업을 시작한 후 다시 시도하세요.');
}

/// OPEN 영업일이 이미 존재할 때 새 영업일 개시 시도
final class BusinessDayAlreadyOpenException extends DomainException {
  const BusinessDayAlreadyOpenException()
      : super('이미 열린 영업일이 있습니다. 기존 영업을 마감한 후 새 영업을 시작하세요.');
}

/// 허용되지 않는 상태 전이 시도 (예: cancelled → delivered)
final class InvalidStateTransitionException extends DomainException {
  const InvalidStateTransitionException({
    required this.from,
    required this.to,
  }) : super('상태를 $from에서 $to로 변경할 수 없습니다.');

  final String from;
  final String to;
}

/// delivered 이후 OrderItems 수정 시도
final class OrderNotModifiableException extends DomainException {
  const OrderNotModifiableException()
      : super('전달 완료된 주문은 수정할 수 없습니다.');
}

/// 마감 시 미처리 주문(PENDING/DELIVERED)이 있을 때 — forceClose=false인 경우
final class PendingOrdersExistException extends DomainException {
  const PendingOrdersExistException({
    required this.pendingCount,
    required this.deliveredCount,
  }) : super('처리 중인 주문이 있어 마감할 수 없습니다. 주문을 완료하거나 취소한 후 다시 시도하세요.');

  final int pendingCount;
  final int deliveredCount;
}

/// balance > 0 인 외상 계좌 삭제 시도
final class CreditAccountHasBalanceException extends DomainException {
  const CreditAccountHasBalanceException({required this.balance})
      : super('미납 잔액이 남아 있는 외상 계좌는 삭제할 수 없습니다.');

  final int balance;
}

/// 활성 주문에서 참조 중인 MenuItem 삭제 시도
final class MenuItemInUseException extends DomainException {
  const MenuItemInUseException()
      : super('진행 중인 주문에서 사용 중인 메뉴는 삭제할 수 없습니다.');
}

/// 활성 주문에 연결된 Seat 삭제 시도
final class SeatInUseException extends DomainException {
  const SeatInUseException()
      : super('진행 중인 주문이 연결된 좌석은 삭제할 수 없습니다.');
}

/// 이미 존재하는 seatNumber로 좌석 생성 시도
final class DuplicateSeatNumberException extends DomainException {
  const DuplicateSeatNumberException(this.seatNumber)
      : super('좌석 번호 "$seatNumber"이(가) 이미 존재합니다.');

  final String seatNumber;
}

final class MenuItemNotFoundException extends DomainException {
  const MenuItemNotFoundException(String id)
      : super('메뉴를 찾을 수 없습니다. (id: $id)');
}

final class SeatNotFoundException extends DomainException {
  const SeatNotFoundException(String id)
      : super('좌석을 찾을 수 없습니다. (id: $id)');
}

final class OrderNotFoundException extends DomainException {
  const OrderNotFoundException(String id)
      : super('주문을 찾을 수 없습니다. (id: $id)');
}

final class OrderItemNotFoundException extends DomainException {
  const OrderItemNotFoundException(String id)
      : super('주문 항목을 찾을 수 없습니다. (id: $id)');
}

final class CreditAccountNotFoundException extends DomainException {
  const CreditAccountNotFoundException(String id)
      : super('외상 계좌를 찾을 수 없습니다. (id: $id)');
}
