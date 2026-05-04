<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-05-04 | Updated: 2026-05-04 -->

# lib/domain/usecases/seat/

## Purpose
좌석 관리 UseCase (생성·수정·삭제).

## Key Files

| File | Description |
|------|-------------|
| `create_seat_use_case.dart` | 좌석 생성 |
| `update_seat_use_case.dart` | 좌석 수정 |
| `delete_seat_use_case.dart` | 좌석 삭제 — 활성 주문 연결 시 삭제 불가 |

## For AI Agents

### Working In This Directory
- **삭제 제약**: 활성 주문(PENDING/DELIVERED)이 연결된 Seat는 삭제 불가 → 예외 발생
- `test/domain/usecases/seat/` 에 3개 테스트 파일

## Dependencies

### Internal
- `ISeatRepository`, `IOrderRepository`
- `Seat` 엔티티

<!-- MANUAL: -->
