<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-05-04 | Updated: 2026-05-04 -->

# test/domain/

## Purpose
domain 레이어 단위 테스트. UseCase, 엔티티, value objects, 예외 클래스를 mockito로 테스트한다.

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `usecases/` | UseCase 단위 테스트 (mockito repository mock) |
| `entities/` | 엔티티 단위 테스트 |
| `value_objects/` | value object 단위 테스트 |
| `exceptions/` | 예외 클래스 테스트 |

## Key Files (usecases/)

| File | Description |
|------|-------------|
| `create_order_use_case_test.dart` | 주문 생성 UseCase 테스트 |
| `deliver_order_use_case_test.dart` | 주문 전달 UseCase 테스트 |
| `pay_immediate_use_case_test.dart` | 즉시 결제 UseCase 테스트 |
| `pay_credit_use_case_test.dart` | 외상 결제 UseCase 테스트 |
| `cancel_order_use_case_test.dart` | 주문 취소 UseCase 테스트 |
| `refund_order_use_case_test.dart` | 주문 환불 UseCase 테스트 |
| `open_business_day_use_case_test.dart` | 영업 개시 UseCase 테스트 |
| `close_business_day_use_case_test.dart` | 영업 마감 UseCase 테스트 |
| `pay_credit_account_use_case_test.dart` | 외상 납부 UseCase 테스트 |
| `*.mocks.dart` | mockito 자동 생성 mock 파일 |

## For AI Agents

### Working In This Directory
- mock 파일(`*.mocks.dart`)은 build_runner 자동 생성 — 직접 수정 금지
- mock 재생성: `dart run build_runner build --delete-conflicting-outputs`
- 영업일 의존 UseCase 테스트 시 `mockBusinessDayRepo.getOpen()`에 OPEN BusinessDay stub 필수
- 트랜잭션 UseCase 테스트 시 원자성 검증 (양쪽 호출 여부 확인)

### Common Patterns
```dart
@GenerateMocks([IOrderRepository, IBusinessDayRepository])
void main() {
  late MockIOrderRepository mockOrderRepo;
  late MockIBusinessDayRepository mockBusinessDayRepo;

  setUp(() {
    mockOrderRepo = MockIOrderRepository();
    mockBusinessDayRepo = MockIBusinessDayRepository();
    when(mockBusinessDayRepo.getOpen()).thenAnswer((_) async => openBusinessDay);
  });
}
```

<!-- MANUAL: -->
