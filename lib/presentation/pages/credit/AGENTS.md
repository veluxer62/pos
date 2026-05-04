<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-05-04 | Updated: 2026-05-04 -->

# lib/presentation/pages/credit/

## Purpose
외상 장부 UI. 외상 계정 목록·상세 조회, 납부 처리 화면.

## Key Files

| File | Description |
|------|-------------|
| `credit_page.dart` | 외상 탭 진입점 |
| `credit_account_list_page.dart` | 외상 계정 목록 |
| `credit_account_detail_page.dart` | 외상 계정 상세 — 거래 내역, 납부 액션 |
| `widgets/` | 외상 관련 공용 위젯 |

## For AI Agents

### Working In This Directory
- balance 표시는 `CurrencyFormatter` 사용
- 납부 후 balance 실시간 업데이트 (provider invalidate)
- `balance == 0` 인 계정만 삭제 가능 — UI에서 조건 분기 필요

### Testing Requirements
- `test/presentation/pages/` (credit 전용 디렉토리 없으면 pages 레벨에서 테스트)

<!-- MANUAL: -->
