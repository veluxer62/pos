<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-05-04 | Updated: 2026-05-04 -->

# lib/presentation/pages/settings/

## Purpose
설정 UI. 메뉴 항목 관리(생성·수정·삭제)와 좌석 관리(생성·수정·삭제) 화면.

## Key Files

| File | Description |
|------|-------------|
| `settings_page.dart` | 설정 탭 진입점 |
| `menu_item_list_page.dart` | 메뉴 항목 목록 및 관리 |
| `seat_list_page.dart` | 좌석 목록 및 관리 |
| `widgets/` | 설정 관련 공용 위젯 |

## For AI Agents

### Working In This Directory
- 메뉴 삭제 시 활성 주문 참조 여부 확인 후 soft delete 처리 (UI에서 피드백 표시)
- 좌석 삭제 시 활성 주문 연결 여부 확인 (UI에서 에러 표시)
- 메뉴 가격 입력은 정수(KRW 원 단위)만 허용

### Testing Requirements
- `test/presentation/pages/` 에 위젯 테스트

<!-- MANUAL: -->
