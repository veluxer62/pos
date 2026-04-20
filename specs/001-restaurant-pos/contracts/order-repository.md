# Repository Contract: IOrderRepository

**Layer**: `domain/repositories/`
**Implementation**: `data/local/repositories/LocalOrderRepository`

---

```dart
abstract interface class IOrderRepository {
  /// 새 주문 생성. OPEN 영업일이 없으면 BusinessDayNotFoundException.
  Future<Order> create({
    required String businessDayId,
    required String seatId,
    required List<OrderItemInput> items,
  });

  /// 주문 단건 조회. 없으면 null.
  Future<Order?> findById(String id);

  /// 영업일 내 주문 목록. status 지정 시 필터링.
  Future<List<Order>> findByBusinessDay(
    String businessDayId, {
    OrderStatus? status,
  });

  /// 좌석의 활성 주문(PENDING/DELIVERED) 조회. 없으면 null.
  Future<Order?> findActiveOrderBySeat(String seatId);

  /// 주문 상태를 DELIVERED로 전이. PENDING이 아니면 InvalidStateTransitionException.
  Future<Order> deliver(String orderId);

  /// 주문을 즉시 결제(PAID)로 전이. DELIVERED가 아니면 InvalidStateTransitionException.
  Future<Order> payImmediate(String orderId);

  /// 주문을 외상(CREDITED)으로 전이. DELIVERED가 아니면 InvalidStateTransitionException.
  /// creditAccountId 필수.
  Future<Order> payCredit(String orderId, String creditAccountId);

  /// 주문 취소(CANCELLED). PENDING 또는 DELIVERED만 가능.
  Future<Order> cancel(String orderId);

  /// 주문 환불(REFUNDED). PAID만 가능.
  Future<Order> refund(String orderId);

  /// OrderItem 추가. DELIVERED 이후면 OrderNotModifiableException.
  Future<Order> addItem(String orderId, OrderItemInput item);

  /// OrderItem 수량 변경. quantity=0이면 항목 삭제.
  Future<Order> updateItemQuantity(String orderId, String itemId, int quantity);

  /// 주문 변경 스트림 (Riverpod과 연동).
  Stream<List<Order>> watchByBusinessDay(String businessDayId);
}
```

---

## 타입 정의

```dart
class OrderItemInput {
  final String menuItemId;
  final int quantity; // ≥ 1
}

enum OrderStatus { pending, delivered, paid, credited, cancelled, refunded }
enum PaymentType { immediate, credit }
```

---

## 예외

| 예외 클래스 | 발생 조건 |
|------------|----------|
| `BusinessDayNotFoundException` | OPEN 영업일 없음 |
| `InvalidStateTransitionException` | 허용되지 않은 상태 전이 |
| `OrderNotModifiableException` | DELIVERED 이후 항목 수정 시도 |
| `OrderItemNotFoundException` | 존재하지 않는 OrderItem ID |

---

## 비즈니스 규칙 요약

- `totalAmount`는 Repository가 `OrderItems` 합산으로 계산하여 저장
- 상태 전이 유효성 검사는 UseCase 또는 Repository 레벨에서 수행
- `deliver`, `payImmediate`, `payCredit`, `cancel`은 OPEN 영업일 필요 (`BusinessDayRepository.getOpen()` 참조)
- `refund`는 영업일 무관하게 가능
