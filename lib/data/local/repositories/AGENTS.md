<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-05-04 | Updated: 2026-05-04 -->

# lib/data/local/repositories/

## Purpose
`IXxxRepository` 인터페이스의 drift SQLite 구현체. DAO를 주입받아 도메인 엔티티로 변환하고 원자적 트랜잭션을 처리한다.

## Key Files

| File | Description |
|------|-------------|
| `local_order_repository.dart` | `IOrderRepository` 구현 — 주문 CRUD + 트랜잭션 |
| `local_business_day_repository.dart` | `IBusinessDayRepository` 구현 — 마감 + DailySalesReport 트랜잭션 |
| `local_menu_item_repository.dart` | `IMenuItemRepository` 구현 |
| `local_seat_repository.dart` | `ISeatRepository` 구현 |
| `local_credit_account_repository.dart` | `ICreditAccountRepository` 구현 — 납부 + balance 트랜잭션 |

## For AI Agents

### Working In This Directory
- 클래스명: `LocalXxxRepository implements IXxxRepository`
- 원자적 트랜잭션은 이 레이어에서 처리:
  ```dart
  await db.transaction(() async {
    await businessDayDao.close(id);
    await dailySalesReportDao.insert(report);
  });
  ```
- drift Row → domain Entity 변환 로직 포함
- 백엔드 전환 시 이 파일들을 `RemoteXxxRepository`로 교체 (`core/di/providers.dart`만 수정)

### Testing Requirements
- `test/data/repositories/` — `NativeDatabase.memory()` 사용 (5개 파일)

## Dependencies

### Internal
- `lib/data/local/daos/`
- `lib/domain/repositories/` — 구현 대상 interface
- `lib/domain/entities/`

<!-- MANUAL: -->
