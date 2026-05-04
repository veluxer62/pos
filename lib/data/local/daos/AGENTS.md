<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-05-04 | Updated: 2026-05-04 -->

# lib/data/local/daos/

## Purpose
기능별 drift DAO(Data Access Object). 각 도메인 엔티티에 대응하는 CRUD 및 쿼리 메서드를 제공한다.

## Key Files

| File | Description |
|------|-------------|
| `order_dao.dart` | 주문 쿼리 (생성·조회·상태 변경) |
| `order_dao.g.dart` | 자동 생성 |
| `business_day_dao.dart` | 영업일 쿼리 (개시·마감·조회) |
| `business_day_dao.g.dart` | 자동 생성 |
| `menu_item_dao.dart` | 메뉴 항목 CRUD |
| `menu_item_dao.g.dart` | 자동 생성 |
| `seat_dao.dart` | 좌석 CRUD |
| `seat_dao.g.dart` | 자동 생성 |
| `credit_account_dao.dart` | 외상 계정 CRUD + balance 업데이트 |
| `credit_account_dao.g.dart` | 자동 생성 |
| `credit_transaction_dao.dart` | 외상 거래 내역 CRUD |
| `credit_transaction_dao.g.dart` | 자동 생성 |

## For AI Agents

### Working In This Directory
- `*.g.dart` 파일 직접 수정 금지 — build_runner 자동 생성
- DAO 메서드 추가/변경 시 build_runner 재실행 필수
- 트랜잭션이 필요한 경우 DAO가 아닌 repository 구현체에서 처리

### Testing Requirements
- `test/data/daos/` — `NativeDatabase.memory()` 사용
- 각 DAO별 CRUD + 엣지 케이스 테스트 (5개 파일)

### Common Patterns
```dart
@DriftAccessor(tables: [Orders, OrderItems])
class OrderDao extends DatabaseAccessor<AppDatabase> with _$OrderDaoMixin {
  Future<List<OrderData>> getByBusinessDay(String businessDayId) =>
      (select(orders)..where((o) => o.businessDayId.equals(businessDayId))).get();
}
```

## Dependencies

### Internal
- `lib/data/local/database/tables.dart`

### External
- `drift`

<!-- MANUAL: -->
