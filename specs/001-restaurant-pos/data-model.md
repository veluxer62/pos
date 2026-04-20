# Data Model: Restaurant POS App

**Phase**: 1 — Design
**Date**: 2026-04-19 (updated: Flutter + drift SQLite)
**Storage**: drift 2.x (SQLite), 단일 로컬 DB 파일

---

## 엔티티 관계 다이어그램 (개요)

```
BusinessDay ──1:N──► Order ──1:N──► OrderItem ──N:1──► MenuItem
                       │
                     N:1
                       │
                      Seat

BusinessDay ──1:1──► DailySalesReport

CreditAccount ──1:N──► CreditTransaction ──N:1──► Order (외상 발생 시)
```

---

## drift 공통 규칙

- `UuidTextConverter` 커스텀 컨버터로 UUID를 TEXT로 저장 (dart:math + `uuid` 패키지)
- 날짜/시간: `DateTime`을 INTEGER(millisecondsSinceEpoch)로 저장 (drift 기본)
- Enum: `TextColumn` + `EnumConverter`로 TEXT 저장 (가독성·마이그레이션 안전)
- Boolean: drift `BoolColumn` (내부적으로 INTEGER 0/1)
- 금액: `IntColumn` (KRW 원 단위 정수)
- 모든 테이블에 `id TEXT NOT NULL PRIMARY KEY` (UUID)

---

## 1. MenuItems 테이블

```dart
class MenuItems extends Table {
  TextColumn get id => text()();                        // UUID PK
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get price => integer()();                   // KRW, ≥ 0
  TextColumn get category => text().withLength(min: 1, max: 50)();
  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

**인덱스**: `isAvailable` (주문 생성 시 판매 가능 메뉴 필터)

**비즈니스 규칙**:
- 활성 주문(PENDING/DELIVERED) 참조 중이면 삭제 불가 → `isAvailable = false` 처리
- 가격 변경은 MenuItem만 수정, 기존 OrderItems의 `unitPrice` 스냅샷에 영향 없음

---

## 2. Seats 테이블

```dart
class Seats extends Table {
  TextColumn get id => text()();
  TextColumn get seatNumber => text().withLength(min: 1, max: 20)();  // UNIQUE
  IntColumn get capacity => integer()();                              // ≥ 1
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

**인덱스**: `seatNumber UNIQUE`

**비즈니스 규칙**:
- 활성 주문(PENDING/DELIVERED) 연결 시 삭제 불가
- 수용 인원 수정은 진행 중 주문에 영향 없음

---

## 3. BusinessDays 테이블

```dart
enum BusinessDayStatus { open, closed }

class BusinessDays extends Table {
  TextColumn get id => text()();
  TextColumn get status => textEnum<BusinessDayStatus>()();
  DateTimeColumn get openedAt => dateTime()();
  DateTimeColumn get closedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

**인덱스**: Partial unique — `status = 'open'`인 행은 최대 1개 (애플리케이션 레벨에서 보장)

**비즈니스 규칙**:
- OPEN 영업일은 전체 DB에서 최대 1개 (`BusinessDayDao.getOpen()` null 체크 후 생성)
- OPEN이 없으면 주문 생성·상태 변경 차단 (UseCase 레벨)
- CLOSED 전환 시 `DailySalesReport` 즉시 생성 (트랜잭션 내 처리)

---

## 4. Orders 테이블

```dart
enum OrderStatus { pending, delivered, paid, credited, cancelled, refunded }
enum PaymentType { immediate, credit }

class Orders extends Table {
  TextColumn get id => text()();
  TextColumn get businessDayId => text().references(BusinessDays, #id)();
  TextColumn get seatId => text().references(Seats, #id)();
  TextColumn get status => textEnum<OrderStatus>()();
  IntColumn get totalAmount => integer()();             // KRW, 자동 계산
  TextColumn get paymentType => textEnum<PaymentType>().nullable()(); // PAID/CREDITED 시만
  TextColumn get creditAccountId =>
      text().nullable().references(CreditAccounts, #id)();            // CREDITED 시만
  DateTimeColumn get orderedAt => dateTime()();
  DateTimeColumn get deliveredAt => dateTime().nullable()();
  DateTimeColumn get paidAt => dateTime().nullable()();
  DateTimeColumn get creditedAt => dateTime().nullable()();
  DateTimeColumn get cancelledAt => dateTime().nullable()();
  DateTimeColumn get refundedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

**인덱스**:
- `(businessDayId, status)` — 영업일별 상태 조회
- `(seatId, status)` — 좌석별 활성 주문 조회
- `(creditAccountId, status)` — 외상 계좌별 주문 조회

**상태 전이**:

```
pending ──deliver──► delivered ──pay(immediate)──► paid ──refund──► refunded
             │
             └──pay(credit + accountId)──► credited
             │
pending/delivered ──cancel──► cancelled
```

**비즈니스 규칙**:
- `totalAmount`: `OrderItems` 합산으로 계산, OrderItem 변경 시 재계산 (UseCase 담당)
- `delivered` 이후 OrderItems 수정 차단
- `paymentType = credit`이면 `creditAccountId` 필수

---

## 5. OrderItems 테이블

```dart
class OrderItems extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text().references(Orders, #id)();
  TextColumn get menuItemId => text().references(MenuItems, #id)();
  TextColumn get menuName => text().withLength(min: 1, max: 100)(); // 스냅샷
  IntColumn get unitPrice => integer()();                           // 스냅샷, KRW
  IntColumn get quantity => integer()();                            // ≥ 1
  IntColumn get subtotal => integer()();                            // unitPrice × quantity
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

**인덱스**: `orderId`, `menuItemId`

**비즈니스 규칙**:
- `menuName`, `unitPrice`: 생성 시점 스냅샷 — MenuItem 이후 변경 무관
- `subtotal = unitPrice × quantity` (저장 시 계산, UseCase에서 보장)
- `quantity = 0`이면 항목 삭제로 처리

---

## 6. CreditAccounts 테이블

```dart
class CreditAccounts extends Table {
  TextColumn get id => text()();
  TextColumn get customerName => text().withLength(min: 1, max: 100)();
  IntColumn get balance => integer().withDefault(const Constant(0))(); // KRW, ≥ 0
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

**인덱스**: `balance DESC` (목록 정렬)

**비즈니스 규칙**:
- `balance`: CreditTransactions 합산과 일치 (UseCase에서 원자적 업데이트)
- 잔액 0인 경우에만 삭제 허용
- 고객명 중복 허용 (동명이인 구분은 사용자 책임)

---

## 7. CreditTransactions 테이블

```dart
enum CreditTransactionType { charge, payment }

class CreditTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get creditAccountId => text().references(CreditAccounts, #id)();
  TextColumn get type => textEnum<CreditTransactionType>()();
  IntColumn get amount => integer()();        // KRW, 양수만
  TextColumn get orderId => text().nullable().references(Orders, #id)(); // charge 시
  TextColumn get note => text().nullable().withLength(max: 200)();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

**인덱스**: `(creditAccountId, createdAt)`, `orderId`

**비즈니스 규칙**:
- `charge`: `CreditAccount.balance += amount`, `orderId` 설정
- `payment`: `CreditAccount.balance = max(0, balance - amount)`, `orderId` null
- 두 연산은 drift `transaction()` 블록에서 원자적 처리

---

## 8. DailySalesReports 테이블

```dart
class DailySalesReports extends Table {
  TextColumn get id => text()();
  TextColumn get businessDayId =>
      text().unique().references(BusinessDays, #id)();      // 1:1
  DateTimeColumn get openedAt => dateTime()();               // 스냅샷
  DateTimeColumn get closedAt => dateTime()();               // 스냅샷
  IntColumn get totalRevenue => integer()();                 // PAID 합산
  IntColumn get paidOrderCount => integer()();
  IntColumn get creditedAmount => integer()();               // CREDITED 합산 (미수금)
  IntColumn get creditedOrderCount => integer()();
  IntColumn get cancelledOrderCount => integer()();
  IntColumn get refundedOrderCount => integer()();
  IntColumn get refundedAmount => integer()();
  IntColumn get netRevenue => integer()();                   // totalRevenue - refundedAmount
  TextColumn get menuSummaryJson => text()();                // JSON 직렬화
  TextColumn get hourlySummaryJson => text()();              // JSON 직렬화
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

**비즈니스 규칙**:
- 영업 마감 시 단 한 번 생성, 이후 읽기 전용
- `menuSummaryJson`: `List<MenuSalesItem>` JSON 인코딩
- `hourlySummaryJson`: `List<HourlySalesItem>` JSON 인코딩
- 보고서는 마감 시점 스냅샷이므로 이후 데이터 변경에 영향받지 않음

---

## 마이그레이션 전략

```dart
// AppDatabase 내 MigrationStrategy 설정
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) => m.createAll(),
  onUpgrade: (m, from, to) async {
    // 버전별 명시적 마이그레이션
    if (from < 2) await m.addColumn(orders, orders.creditedAt);
    // ...
  },
);
```

- 스키마 변경 시 버전 번호 증가 + `onUpgrade` 명시적 처리
- 개발 중에는 `destroyEverything()` 허용, 프로덕션에서는 점진적 마이그레이션만

---

## 상태 전이 요약

### Order 상태머신

| 현재 상태 | 이벤트 | 다음 상태 | 시각 필드 | 추가 조건 |
|-----------|--------|-----------|-----------|-----------|
| pending | deliver | delivered | `deliveredAt` | OPEN 영업일 필수 |
| pending | cancel | cancelled | `cancelledAt` | OPEN 영업일 필수 |
| delivered | pay(immediate) | paid | `paidAt` | OPEN 영업일 필수 |
| delivered | pay(credit) | credited | `creditedAt` | OPEN 영업일, `creditAccountId` 필수 |
| delivered | cancel | cancelled | `cancelledAt` | OPEN 영업일 필수 |
| paid | refund | refunded | `refundedAt` | 영업일 무관 |
| credited | — | (최종) | — | CreditTransaction으로 별도 관리 |
| cancelled | — | (최종) | — | — |
| refunded | — | (최종) | — | — |

### BusinessDay 상태머신

| 현재 상태 | 이벤트 | 다음 상태 | 제약 |
|-----------|--------|-----------|------|
| — | open | OPEN | 기존 OPEN 없어야 함 |
| OPEN | close | CLOSED | DailySalesReport 원자적 생성 |
| CLOSED | — | (최종) | — |
