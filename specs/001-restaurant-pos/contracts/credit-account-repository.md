# Repository Contract: ICreditAccountRepository

**Layer**: `domain/repositories/`
**Implementation**: `data/local/repositories/LocalCreditAccountRepository`

---

```dart
abstract interface class ICreditAccountRepository {
  /// 외상 계좌 목록. hasBalance=true: 잔액 있는 계좌만, false: 완납 계좌만.
  Future<List<CreditAccount>> findAll({bool? hasBalance});

  /// ID로 외상 계좌 단건 조회. 없으면 null.
  Future<CreditAccount?> findById(String id);

  /// 외상 계좌 등록.
  Future<CreditAccount> create(String customerName);

  /// 고객명 변경.
  Future<CreditAccount> updateName(String id, String customerName);

  /// 계좌 삭제. balance > 0이면 CreditAccountHasBalanceException.
  Future<void> delete(String id);

  /// 외상 발생 (charge). Order 결제 시 호출.
  /// balance += amount, CreditTransaction(charge) 생성.
  /// Order와 CreditAccount 업데이트는 동일 트랜잭션 내 원자적 처리.
  Future<CreditTransaction> charge({
    required String accountId,
    required String orderId,
    required int amount,
  });

  /// 외상 납부 (payment). balance = max(0, balance - amount).
  /// 초과 납부 시 잔액 0으로 처리, appliedAmount는 실제 차감액.
  Future<PaymentResult> pay({
    required String accountId,
    required int amount,
    String? note,
  });

  /// 거래 이력 조회 (createdAt 역순).
  Future<List<CreditTransaction>> getTransactions(
    String accountId, {
    CreditTransactionType? type,
    int limit = 50,
    int offset = 0,
  });

  /// 외상 계좌 변경 스트림.
  Stream<List<CreditAccount>> watchAll();
}
```

---

## 타입 정의

```dart
enum CreditTransactionType { charge, payment }

class PaymentResult {
  final CreditTransaction transaction;
  final int previousBalance;
  final int appliedAmount;
  final int newBalance;
  final int? overpaidAmount; // 초과 납부 시만 non-null
}
```

---

## 예외

| 예외 클래스 | 발생 조건 |
|------------|----------|
| `CreditAccountNotFoundException` | 계좌 없음 |
| `CreditAccountHasBalanceException` | 삭제 시 잔액 > 0 — `balance` 포함 |

---

## 비즈니스 규칙 요약

- `balance`는 CreditTransactions 합산과 항상 일치 (원자적 업데이트로 보장)
- `charge()`와 Order의 `credited` 전이는 동일 트랜잭션에서 수행 (`IOrderRepository.payCredit()` 참조)
- 고객명 중복 허용 (동명이인 구분은 사용자 책임)
- 잔액 0인 경우에만 계좌 삭제 허용
