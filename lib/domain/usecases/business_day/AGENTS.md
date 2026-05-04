<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-05-04 | Updated: 2026-05-04 -->

# lib/domain/usecases/business_day/

## Purpose
영업일 개시·마감 UseCase. 영업일은 모든 주문·결제의 전제 조건이며 하루에 하나만 존재할 수 있다.

## Key Files

| File | Description |
|------|-------------|
| `open_business_day_use_case.dart` | 영업 개시 — 이미 OPEN인 영업일 있으면 예외 |
| `close_business_day_use_case.dart` | 영업 마감 — DailySalesReport 생성 (동일 트랜잭션) |

## For AI Agents

### Working In This Directory
- `close_business_day_use_case`: 마감 + DailySalesReport 생성은 **반드시 동일 트랜잭션**
- 이미 OPEN 영업일 존재 시 `open` 호출하면 예외 발생
- 영업일 마감 후 모든 주문·결제 UseCase는 `BusinessDayNotFoundException` 발생

### Testing Requirements
- `test/domain/usecases/open_business_day_use_case_test.dart`
- `test/domain/usecases/close_business_day_use_case_test.dart`

## Dependencies

### Internal
- `IBusinessDayRepository`
- `BusinessDay`, `DailySalesReport` 엔티티
- `BusinessDayStatus` value object

<!-- MANUAL: -->
