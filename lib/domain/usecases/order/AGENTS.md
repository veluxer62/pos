<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-05-04 | Updated: 2026-05-04 -->

# lib/domain/usecases/order/

## Purpose
주문 생명주기 전체를 담당하는 UseCase 6개. 생성 → 전달 → 결제(즉시/외상) → 취소/환불 흐름.

## Key Files

| File | Description |
|------|-------------|
| `create_order_use_case.dart` | 주문 생성 — OPEN 영업일 확인 + 좌석·메뉴 검증 |
| `deliver_order_use_case.dart` | 주문 전달 완료 (PENDING → DELIVERED) |
| `pay_immediate_use_case.dart` | 즉시 결제 (DELIVERED → PAID) |
| `pay_credit_use_case.dart` | 외상 결제 — 외상 발생 + Order 상태 변경 (동일 트랜잭션) |
| `cancel_order_use_case.dart` | 주문 취소 (PENDING → CANCELLED) |
| `refund_order_use_case.dart` | 주문 환불 (PAID → REFUNDED) |

## For AI Agents

### Working In This Directory
- 모든 UseCase에서 OPEN 영업일 확인 선행 필수
- `pay_credit_use_case`: 외상 발생(charge) + Order 상태 변경은 **반드시 동일 트랜잭션**
- 상태 전이: `PENDING → DELIVERED → PAID/CANCELLED`, `PAID → REFUNDED`
- `sealed class OrderStatus` exhaustive switch로 유효하지 않은 전이 컴파일 타임 차단

### Testing Requirements
- `test/domain/usecases/` 의 `*_use_case_test.dart` 6개 파일

## Dependencies

### Internal
- `IOrderRepository`, `IBusinessDayRepository`, `ICreditAccountRepository`
- `Order`, `OrderItem`, `CreditAccount` 엔티티
- `OrderStatus`, `PaymentType`, `PaymentResult` value objects

<!-- MANUAL: -->
