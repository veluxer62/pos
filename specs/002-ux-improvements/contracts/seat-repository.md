# Contract: ISeatRepository (변경 사항)

**Feature**: 002-ux-improvements
**Date**: 2026-05-07

---

## 신규 메서드

### `watchAllWithActiveOrders()`

```dart
Stream<List<SeatWithActiveOrder>> watchAllWithActiveOrders();
```

- **목적**: N+1 쿼리 제거 — 좌석 그리드 초기 로드 시 단일 JOIN 쿼리로 처리
- **반환값**: 모든 좌석과 각 좌석의 활성 주문(PENDING/DELIVERED)을 묶은 목록
  - 활성 주문이 없는 좌석: `activeOrder == null`
  - 좌석 번호(seatNumber) 오름차순 정렬
- **후행 조건**: 주문 상태가 변경될 때마다 stream이 새 값을 방출

---

## Value Object: `SeatWithActiveOrder`

```dart
// lib/domain/value_objects/seat_with_active_order.dart
class SeatWithActiveOrder {
  const SeatWithActiveOrder({
    required this.seat,
    this.activeOrder,
  });

  final Seat seat;

  /// PENDING 또는 DELIVERED 상태 주문. 없으면 null.
  final Order? activeOrder;

  bool get hasActiveOrder => activeOrder != null;
}
```

---

## 기존 메서드 유지

`watchAll()`, `findById()`, `create()`, `update()`, `delete()` 등 기존 메서드는 변경 없이 유지.
`activeOrderBySeatProvider(seatId)` provider도 다른 화면(OrderDetailPage 등)에서 사용되므로 삭제하지 않음.
