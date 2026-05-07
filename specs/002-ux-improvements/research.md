# Research: UX 개선 및 버그 수정

**Feature**: 002-ux-improvements
**Date**: 2026-05-07
**Status**: Complete

---

## Phase 0 Unknowns — Resolved

### R-01: drift 마이그레이션 — nullable 컬럼 추가 방법

**Decision**: `addColumn` 마이그레이션 전략 사용. nullable TextColumn을 기존 테이블에 추가한다.

**Rationale**: drift의 `MigrationStrategy.onUpgrade`에서 `m.addColumn(table, column)` 호출로
nullable 컬럼을 안전하게 추가할 수 있다. SQLite는 기존 행에 NULL을 자동 채운다.
컬럼 삭제·재정의 없이 순수 추가이므로 기존 데이터에 영향 없음.

**Alternatives considered**:
- 테이블 재생성(recreateTable): 데이터 손실 위험 — 불채택
- schemaVersion 미증가: 마이그레이션 미실행, 런타임 에러 — 불채택

**Implementation**:
```dart
// app_database.dart
@override
MigrationStrategy get migration => MigrationStrategy(
  onUpgrade: (m, from, to) async {
    if (from < [NEW_VERSION]) {
      await m.addColumn(creditAccounts, creditAccounts.phone);
      await m.addColumn(creditAccounts, creditAccounts.note);
    }
  },
);
```

---

### R-02: N+1 쿼리 제거 — drift batch query 패턴

**Decision**: `SELECT seats.*, orders.* FROM seats LEFT JOIN orders ON ... WHERE status IN (...)` JOIN 쿼리를 drift의 `customSelect` 또는 `select(seats).join([...])` API로 구현.

**Rationale**: drift는 `JoinedSelectStatement`를 지원하여 multiple table join을 단일 SQL로
실행할 수 있다. `watchAllWithActiveOrders()`를 `Stream<List<SeatWithActiveOrder>>`로 반환하면
기존 watch 패턴과 동일하게 Riverpod provider에서 `ref.watch`로 사용 가능하다.

**Alternatives considered**:
- 개별 `watchActiveOrderBySeat(seatId)` N회 호출 유지: 좌석 수에 비례하여 DB 쿼리 증가 — 불채택
- `SeatDao.getAll()` + `OrderDao.getActiveBySeat()` 순차 호출: 별개 쿼리 2회이나 N+1보다는 낫지만 실시간 stream 구성 복잡 — 불채택

**Implementation sketch**:
```dart
Stream<List<SeatWithActiveOrder>> watchAllWithActiveOrders() {
  final query = select(seats).join([
    leftOuterJoin(
      orders,
      orders.seatId.equalsExp(seats.id) &
      orders.status.isIn(['pending', 'delivered']),
    ),
  ]);
  return query.watch().map((rows) => rows.map((row) {
    final seat = row.readTable(seats);
    final order = row.readTableOrNull(orders);
    return SeatWithActiveOrder(seat: seat, activeOrder: order);
  }).toList());
}
```

---

### R-03: share_plus — Flutter 파일 공유 패턴

**Decision**: `share_plus ^10.x` 패키지 사용. `Share.shareXFiles([XFile(path)])` API로 임시 파일 공유.

**Rationale**: Flutter 공식 생태계 패키지. Android Intent, iOS UIActivityViewController를 추상화.
`path_provider`로 임시 디렉토리 경로 획득 후 JSON 파일 생성, Share sheet 호출.

**Alternatives considered**:
- `open_file` 패키지: 공유가 아닌 파일 열기 — 이메일 전송에 부적합, 불채택
- 직접 플랫폼 채널: 유지보수 부담 — 불채택

**Dependencies to add**:
```yaml
# pubspec.yaml
dependencies:
  share_plus: ^10.0.0
  path_provider: ^2.1.0  # 이미 있을 가능성 높음 — 확인 필요
```

---

### R-04: 에러 메시지 한국어 매핑 — presentation 레이어 경계

**Decision**: `lib/presentation/utils/error_message_mapper.dart` 유틸 클래스를 presentation 레이어에만 두고, domain exception은 그대로 유지.

**Rationale**: domain exception에 UI 메시지를 추가하면 domain 레이어가 presentation에 의존하게
되어 Clean Architecture 위반. presentation에서만 변환한다.

**Pattern**:
```dart
// error_message_mapper.dart
String mapToUserMessage(Object error) => switch (error) {
  BusinessDayNotFoundException() => '영업을 시작한 후 주문을 생성할 수 있습니다.\n홈 화면에서 영업 시작을 눌러주세요.',
  OrderNotEditableException() => '완료된 주문은 수정할 수 없습니다.',
  MenuNotAvailableException() => '현재 판매하지 않는 메뉴입니다.',
  MinimumOrderItemException() => '주문 항목이 최소 1개 이상이어야 합니다.',
  _ => '오류가 발생했습니다. 앱을 다시 시작해 주세요.',
};
```

---

### R-05: 기존 코드베이스 현황 파악

현재 `order_detail_page.dart:57` 버그:
- `_OrderItemList(items: const [], editable: isPending)` — DB 데이터 미연결
- `OrderDao`에 `watchItems(orderId)` 또는 유사 메서드 존재 여부 → 구현 시 확인 필요
- 없으면 `OrderDao`에 `watchOrderItems(String orderId)` 추가

`seat_grid_page.dart` N+1 현황:
- `ref.watch(activeOrderBySeatProvider(seat.id))` 패턴이 각 SeatCard에서 호출됨
- 좌석 수 = DB 쿼리 수 (N+1 확인됨)

`CreditAccount` 현재 필드:
- id, name, balance, createdAt, updatedAt
- phone, note 필드 없음 → 마이그레이션 필요

현재 `schemaVersion` 확인 필요 → 구현 시 `app_database.dart`에서 실제 버전 확인 후 +1.

---

## Technology Decisions Summary

| 항목 | 결정 | 근거 |
|------|------|------|
| drift 마이그레이션 | `addColumn` nullable | 기존 데이터 무손실, SQLite NULL 자동 채움 |
| Batch 쿼리 | drift `join()` + `Stream.watch()` | 기존 watch 패턴 유지, N+1 제거 |
| 파일 공유 | `share_plus ^10` + `path_provider` | Flutter 공식 생태계, 플랫폼 추상화 |
| 에러 메시지 | presentation 유틸 `switch` 매핑 | domain 순수성 유지, exhaustive 컴파일 안전 |
| 폰트 토큰 | `AppTypography` 확장 | 디자인 토큰 원칙, raw 값 금지 |
