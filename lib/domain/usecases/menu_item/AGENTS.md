<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-05-04 | Updated: 2026-05-04 -->

# lib/domain/usecases/menu_item/

## Purpose
메뉴 항목 관리 UseCase (생성·수정·삭제).

## Key Files

| File | Description |
|------|-------------|
| `create_menu_item_use_case.dart` | 메뉴 항목 생성 |
| `update_menu_item_use_case.dart` | 메뉴 항목 수정 |
| `delete_menu_item_use_case.dart` | 메뉴 항목 삭제 — 활성 주문 참조 시 soft delete |

## For AI Agents

### Working In This Directory
- **삭제 제약**: 활성 주문(PENDING/DELIVERED)에서 참조 중인 MenuItem은 실제 삭제 불가 → `isAvailable=false`로 soft delete
- `test/domain/usecases/menu_item/` 에 3개 테스트 파일

## Dependencies

### Internal
- `IMenuItemRepository`, `IOrderRepository`
- `MenuItem` 엔티티

<!-- MANUAL: -->
