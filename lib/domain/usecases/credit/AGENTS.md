<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-05-04 | Updated: 2026-05-04 -->

# lib/domain/usecases/credit/

## Purpose
외상 장부 관리 UseCase. 외상 계정 생성과 외상 납부(balance 업데이트).

## Key Files

| File | Description |
|------|-------------|
| `create_credit_account_use_case.dart` | 외상 계정 생성 |
| `pay_credit_account_use_case.dart` | 외상 납부 — 납부 + CreditAccount balance 업데이트 (동일 트랜잭션) |

## For AI Agents

### Working In This Directory
- `pay_credit_account_use_case`: 납부 + balance 업데이트는 **반드시 동일 트랜잭션**
- CreditAccount 삭제는 `balance == 0`인 경우만 허용 (이 UseCase 범위 밖)

### Testing Requirements
- `test/domain/usecases/pay_credit_account_use_case_test.dart`

## Dependencies

### Internal
- `ICreditAccountRepository`
- `CreditAccount`, `CreditTransaction` 엔티티
- `CreditTransactionType` value object

<!-- MANUAL: -->
