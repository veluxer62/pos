<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-05-04 | Updated: 2026-05-04 -->

# lib/presentation/pages/

## Purpose
기능 도메인별 페이지 모음. 각 도메인 디렉토리 안에 페이지 파일과 `widgets/` 하위 디렉토리가 있다.

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `order/` | 좌석 선택·주문 생성·주문 상세·주문 목록 (see `order/AGENTS.md`) |
| `payment/` | 결제 (즉시/외상) 페이지 |
| `business_day/` | 영업 개시/마감·일일 매출 보고서·판매 이력 |
| `credit/` | 외상 계정 목록·상세·납부 |
| `settings/` | 메뉴 항목·좌석 설정 |

## For AI Agents

### Working In This Directory
- 페이지는 `ConsumerWidget` 또는 `ConsumerStatefulWidget` 사용
- 상태는 `ref.watch(xxxProvider)` — `AsyncValue` 처리 필수 (`loading`, `error`, `data`)
- 네비게이션은 `context.go()` / `context.push()` (go_router)
- 디자인 토큰 사용 필수 (`AppColors`, `AppSpacing`, `AppTypography`)
- 버튼 최소 터치 영역 48dp, `Semantics` 위젯 적용

### Testing Requirements
- `test/presentation/pages/` 에 위젯 테스트

<!-- MANUAL: -->
