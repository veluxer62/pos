<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-05-04 | Updated: 2026-05-04 -->

# test/data/

## Purpose
data 레이어 통합 테스트. `NativeDatabase.memory()`로 in-memory SQLite를 생성하여 DAO·Repository 구현체를 실제 DB로 테스트한다.

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `daos/` | DAO 통합 테스트 (5개 파일) |
| `repositories/` | Repository 구현체 통합 테스트 (5개 파일) |

## Key Files

| File | Description |
|------|-------------|
| `daos/order_dao_test.dart` | OrderDao CRUD + 쿼리 테스트 |
| `daos/business_day_dao_test.dart` | BusinessDayDao 테스트 |
| `daos/menu_item_dao_test.dart` | MenuItemDao 테스트 |
| `daos/seat_dao_test.dart` | SeatDao 테스트 |
| `daos/credit_account_dao_test.dart` | CreditAccountDao 테스트 |
| `repositories/local_order_repository_test.dart` | LocalOrderRepository 테스트 |
| `repositories/local_business_day_repository_test.dart` | 마감 트랜잭션 포함 테스트 |
| `repositories/local_menu_item_repository_test.dart` | soft delete 포함 테스트 |
| `repositories/local_seat_repository_test.dart` | 삭제 제약 테스트 |
| `repositories/local_credit_account_repository_test.dart` | 납부 트랜잭션 테스트 |

## For AI Agents

### Working In This Directory
- **mock DB 절대 금지** — 반드시 `NativeDatabase.memory()` 사용
- `setUp()`에서 in-memory DB 생성, `tearDown()`에서 `await db.close()` 필수
- 트랜잭션 테스트: 중간 실패 시 롤백 여부 검증 필수

### Common Patterns
```dart
late AppDatabase db;

setUp(() async {
  db = AppDatabase(NativeDatabase.memory());
});

tearDown(() async {
  await db.close();
});
```

<!-- MANUAL: -->
