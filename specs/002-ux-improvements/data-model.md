# Data Model Changes: UX 개선 및 버그 수정

**Feature**: 002-ux-improvements
**Date**: 2026-05-07

---

## 변경 요약

| 항목 | 변경 유형 | 설명 |
|------|-----------|------|
| `CreditAccounts` 테이블 | 컬럼 추가 | `phone TEXT`, `note TEXT` nullable 추가 |
| `CreditAccount` entity | 필드 추가 | `phone?`, `note?` nullable String |
| `OrderDao` | 메서드 추가 | `watchItemsByOrder(orderId)` Stream |
| `SeatDao` | 메서드 추가 | `watchAllWithActiveOrders()` JOIN Stream |
| `SeatWithActiveOrder` | VO 신규 | Seat + nullable Order |
| drift schemaVersion | 1 → 2 | CreditAccounts 컬럼 추가로 버전 증가 |

---

## 1. CreditAccounts 테이블 변경

### 현재 스키마

```dart
class CreditAccounts extends Table {
  TextColumn get id => text()();
  TextColumn get customerName => text()();
  IntColumn get balance => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
```

### 변경 후 스키마 (schemaVersion: 2)

```dart
class CreditAccounts extends Table {
  TextColumn get id => text()();
  TextColumn get customerName => text()();
  IntColumn get balance => integer().withDefault(const Constant(0))();
  // 신규 nullable 필드 — 기존 데이터: NULL
  TextColumn get phone => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
```

### 마이그레이션 스크립트

```dart
// app_database.dart
@override
int get schemaVersion => 2;

@override
MigrationStrategy get migration => MigrationStrategy(
  onUpgrade: (m, from, to) async {
    if (from < 2) {
      await m.addColumn(creditAccounts, creditAccounts.phone);
      await m.addColumn(creditAccounts, creditAccounts.note);
    }
  },
);
```

---

## 2. CreditAccount 엔티티 변경

### 현재

```dart
class CreditAccount {
  final String id;
  final String customerName;
  final int balance;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### 변경 후

```dart
class CreditAccount {
  final String id;
  final String customerName;
  final int balance;
  final String? phone;   // 신규
  final String? note;    // 신규
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

- `phone`: 자유 문자열 (형식 검증 없음, 예: "010-1234-5678")
- `note`: 최대 500자 제한 없음 (UI 입력 필드 힌트로 안내)

---

## 3. OrderDao 메서드 추가

### 신규: `watchItemsByOrder(String orderId)`

P0 버그 수정을 위해 `findItemsByOrder`의 Stream 버전이 필요.
현재 `findItemsByOrder`는 `Future<List<OrderItem>>`이나 order_detail_page에서
실시간 반영을 위해 Stream 버전이 필요하다.

```dart
// order_dao.dart
Stream<List<OrderItem>> watchItemsByOrder(String orderId) {
  return (select(orderItems)
        ..where((t) => t.orderId.equals(orderId))
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .watch()
      .map((rows) => rows.map(_itemRowToEntity).toList());
}
```

### Provider 연결

```dart
// order_providers.dart
@riverpod
Stream<List<OrderItem>> orderItems(Ref ref, String orderId) {
  final dao = ref.watch(orderDaoProvider);
  return dao.watchItemsByOrder(orderId);
}
```

---

## 4. SeatDao 메서드 추가 (N+1 해결)

### 신규 VO: `SeatWithActiveOrder`

```dart
// lib/domain/value_objects/seat_with_active_order.dart
class SeatWithActiveOrder {
  const SeatWithActiveOrder({required this.seat, this.activeOrder});
  final Seat seat;
  final Order? activeOrder;  // PENDING 또는 DELIVERED 상태 주문, 없으면 null
}
```

### 신규: `watchAllWithActiveOrders()`

```dart
// seat_dao.dart
Stream<List<SeatWithActiveOrder>> watchAllWithActiveOrders() {
  final activeStatuses = [
    OrderStatusValue.pending.name,
    OrderStatusValue.delivered.name,
  ];

  final query = select(seats).join([
    leftOuterJoin(
      orders,
      orders.seatId.equalsExp(seats.id) &
      orders.status.isIn(activeStatuses),
    ),
  ])
    ..orderBy([OrderingTerm.asc(seats.seatNumber)]);

  return query.watch().map((rows) {
    return rows.map((row) {
      final seat = _seatRowToEntity(row.readTable(seats));
      final orderRow = row.readTableOrNull(orders);
      final order = orderRow != null ? _orderRowToEntity(orderRow) : null;
      return SeatWithActiveOrder(seat: seat, activeOrder: order);
    }).toList();
  });
}
```

### Provider 연결

```dart
// seat_providers.dart (신규 또는 기존 파일 업데이트)
@riverpod
Stream<List<SeatWithActiveOrder>> seatsWithActiveOrders(Ref ref) {
  final dao = ref.watch(seatDaoProvider);
  return dao.watchAllWithActiveOrders();
}
```

---

## 스키마 버전 이력

| 버전 | 변경 내용 | 날짜 |
|------|-----------|------|
| 1 | 초기 스키마 (Orders, OrderItems, Seats, MenuItems, BusinessDays, DailySalesReports, CreditAccounts, CreditTransactions) | 2026-04-19 |
| 2 | CreditAccounts에 `phone`, `note` nullable TEXT 컬럼 추가 | 2026-05-07 |

---

## 의존성 추가

```yaml
# pubspec.yaml dependencies에 추가
share_plus: ^10.0.0
```

`path_provider`는 기존에 이미 포함되어 있을 가능성이 높으므로 `pubspec.yaml` 확인 후 없으면 추가:
```yaml
path_provider: ^2.1.0
```
