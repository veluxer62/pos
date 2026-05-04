<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-05-04 | Updated: 2026-05-04 -->

# lib/presentation/pages/business_day/

## Purpose
영업일 관리 UI. 영업 개시/마감, 일일 매출 보고서, 판매 이력 화면.

## Key Files

| File | Description |
|------|-------------|
| `business_day_page.dart` | 영업 개시/마감 메인 화면 |
| `daily_sales_report_page.dart` | 당일 매출 보고서 상세 |
| `report_page.dart` | 보고서 목록 |
| `sales_history_page.dart` | 판매 이력 조회 |
| `widgets/` | 영업일 관련 공용 위젯 |

## For AI Agents

### Working In This Directory
- 영업 마감 시 확인 다이얼로그(`confirm_dialog.dart`) 필수
- 매출 금액은 `CurrencyFormatter` 사용
- 마감 완료 후 DailySalesReport 자동 표시

### Testing Requirements
- `test/presentation/pages/business_day/`

<!-- MANUAL: -->
