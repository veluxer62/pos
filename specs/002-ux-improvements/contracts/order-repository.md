# Contract: IOrderRepository (변경 사항)

**Feature**: 002-ux-improvements
**Date**: 2026-05-07

---

## 신규 메서드

### `watchItemsByOrder(String orderId)`

```dart
Stream<List<OrderItem>> watchItemsByOrder(String orderId);
```

- **목적**: 주문 항목 목록 실시간 스트림 — `order_detail_page.dart` P0 버그 수정용
- **선행 조건**: orderId에 해당하는 주문이 존재해야 함
- **후행 조건**: orderId에 속한 OrderItem 목록을 생성 시각 오름차순으로 방출
- **에러**: orderId 해당 주문 없으면 빈 Stream 방출 (예외 아님)

---

## UseCase 신규 추가

### `AddOrderItemUseCase`

```dart
class AddOrderItemUseCase {
  Future<void> execute({
    required String orderId,
    required String menuItemId,
    required int quantity,
  });
}
```

**비즈니스 규칙**:
- 주문 상태가 PENDING이어야 함 — 아니면 `OrderNotEditableException`
- `menuItemId`에 해당하는 메뉴가 `isAvailable == true`이어야 함 — 아니면 `MenuNotAvailableException`
- `quantity >= 1`이어야 함 — 아니면 `ArgumentError`
- 항목 추가 후 `order.totalAmount`를 재계산하여 업데이트

**예외 타입**:
```dart
class OrderNotEditableException implements Exception {
  final String orderId;
  final String currentStatus;
}

class MenuNotAvailableException implements Exception {
  final String menuItemId;
}
```

---

### `RemoveOrderItemUseCase`

```dart
class RemoveOrderItemUseCase {
  Future<void> execute({
    required String orderId,
    required String orderItemId,
  });
}
```

**비즈니스 규칙**:
- 주문 상태가 PENDING이어야 함 — 아니면 `OrderNotEditableException`
- 해당 주문에 항목이 2개 이상이어야 함 — 마지막 항목이면 `MinimumOrderItemException`
- 항목 제거 후 `order.totalAmount`를 재계산하여 업데이트

**예외 타입**:
```dart
class MinimumOrderItemException implements Exception {
  final String orderId;
}
```

---

## DAO 변경 사항

### `OrderDao.watchItemsByOrder(String orderId)`

```dart
Stream<List<OrderItem>> watchItemsByOrder(String orderId);
```

### `OrderDao.addItem(String orderId, String menuItemId, int quantity)`

```dart
Future<OrderItem> addItem({
  required String orderId,
  required String menuItemId,
  required String menuName,     // 스냅샷
  required int unitPrice,       // 스냅샷
  required int quantity,
});
```

- 내부에서 `subtotal = unitPrice * quantity` 계산
- 항목 추가 후 order.totalAmount drift transaction 내에서 업데이트

### `OrderDao.removeItem(String orderId, String orderItemId)`

```dart
Future<void> removeItem({
  required String orderId,
  required String orderItemId,
});
```

- 항목 삭제 후 order.totalAmount drift transaction 내에서 재계산 업데이트
