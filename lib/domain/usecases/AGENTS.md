<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-05-04 | Updated: 2026-05-04 -->

# lib/domain/usecases/

## Purpose
비즈니스 로직 UseCase 모음. 기능 도메인별로 하위 디렉토리로 분리된다. 각 UseCase는 단일 책임 원칙에 따라 하나의 비즈니스 동작만 담당하며, repository interface를 주입받아 사용한다.

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `order/` | 주문 생성·전달·취소·환불·결제 UseCase (6개) |
| `business_day/` | 영업일 개시·마감 UseCase (2개) |
| `credit/` | 외상 계정 생성·납부 UseCase (2개) |
| `menu_item/` | 메뉴 항목 생성·수정·삭제 UseCase (3개) |
| `seat/` | 좌석 생성·수정·삭제 UseCase (3개) |

## For AI Agents

### Working In This Directory
- 모든 UseCase는 OPEN 영업일 확인 선행 필수:
  ```dart
  final businessDay = await businessDayRepo.getOpen();
  if (businessDay == null) throw BusinessDayNotFoundException();
  ```
- UseCase 구현 전 `test/domain/usecases/` 에 테스트 먼저 작성 (TDD)
- 삭제 제약 준수:
  - MenuItem: 활성 주문 참조 중이면 `isAvailable=false` soft delete
  - Seat: 활성 주문 연결 시 삭제 불가
  - CreditAccount: `balance == 0`인 경우만 삭제

### Testing Requirements
- `test/domain/usecases/` — `@GenerateMocks` + mockito

### Common Patterns
```dart
class CreateOrderUseCase {
  const CreateOrderUseCase(this._orderRepo, this._businessDayRepo, ...);
  Future<Order> execute(CreateOrderParams params) async {
    final day = await _businessDayRepo.getOpen();
    if (day == null) throw BusinessDayNotFoundException();
    // ...
  }
}
```

## Dependencies

### Internal
- `lib/domain/repositories/` — 주입받는 interface
- `lib/domain/entities/` — 반환·파라미터 타입
- `lib/domain/exceptions/` — 예외 발생

<!-- MANUAL: -->
