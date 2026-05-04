<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-05-04 | Updated: 2026-05-04 -->

# lib/presentation/pages/order/

## Purpose
주문 흐름 UI. 좌석 선택 → 주문 생성 → 주문 상세 → 주문 목록 화면으로 구성된다.

## Key Files

| File | Description |
|------|-------------|
| `seat_grid_page.dart` | 좌석 그리드 — 좌석 선택 화면 |
| `create_order_page.dart` | 주문 생성 — 메뉴 선택 및 수량 입력 |
| `create_order_page.g.dart` | 자동 생성 (build_runner) |
| `order_page.dart` | 주문 목록 페이지 |
| `order_detail_page.dart` | 주문 상세 — 항목 확인, 전달/취소/결제 액션 |
| `widgets/` | 주문 관련 공용 위젯 |

## For AI Agents

### Working In This Directory
- `create_order_page.g.dart` 직접 수정 금지
- 주문 생성 전 OPEN 영업일 확인은 provider 레벨에서 처리
- 좌석 그리드는 태블릿 가로 레이아웃 최적화 필수

### Testing Requirements
- `test/presentation/pages/order/`

<!-- MANUAL: -->
