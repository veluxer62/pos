# Contract: ICreditAccountRepository (변경 사항)

**Feature**: 002-ux-improvements
**Date**: 2026-05-07

---

## 엔티티 변경

### CreditAccount (phone, note 필드 추가)

```dart
class CreditAccount {
  const CreditAccount({
    required this.id,
    required this.customerName,
    required this.balance,
    this.phone,   // 신규 nullable
    this.note,    // 신규 nullable
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String customerName;
  final int balance;
  final String? phone;  // 연락처 (자유 문자열, 형식 검증 없음)
  final String? note;   // 메모 (자유 문자열)
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

---

## 변경된 메서드 시그니처

### `create(String customerName, {String? phone, String? note})`

```dart
Future<CreditAccount> create(
  String customerName, {
  String? phone,
  String? note,
});
```

- 기존: `create(String customerName)`
- 변경: phone, note 선택적 파라미터 추가
- 하위 호환: 기존 호출 코드 수정 불필요 (named optional)

### `update(CreditAccount account)`

```dart
Future<void> update(CreditAccount account);
```

- 변경 없음. `CreditAccount`에 phone/note 필드가 추가되었으므로 자동으로 저장됨.

---

## 마이그레이션 보장

- schemaVersion 1 → 2 업그레이드 시 기존 계좌의 phone/note는 NULL로 설정됨
- NULL 값은 entity에서 `phone == null`로 표현되며 UI에서 "등록되지 않음"으로 처리
- 마이그레이션 테스트: `test/data/migrations/migration_v2_test.dart`에서 검증
