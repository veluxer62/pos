<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-05-04 | Updated: 2026-05-04 -->

# lib/presentation/pages/payment/

## Purpose
결제 처리 UI. 즉시 결제와 외상 결제 두 가지 흐름을 지원한다.

## Key Files

| File | Description |
|------|-------------|
| `payment_page.dart` | 결제 선택 — 즉시결제/외상결제 분기 |
| `widgets/` | 결제 관련 공용 위젯 |

## For AI Agents

### Working In This Directory
- 결제 완료 후 주문 목록으로 복귀 (go_router `context.go()`)
- 외상 결제 시 외상 계정 선택 UI 포함
- 결제 금액은 `CurrencyFormatter` 사용

### Testing Requirements
- `test/presentation/pages/payment/`

<!-- MANUAL: -->
