<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-05-04 | Updated: 2026-05-04 -->

# lib/domain/

## Purpose
순수 Dart 비즈니스 로직 레이어. Flutter·drift에 의존하지 않는다. 엔티티, 추상 repository 인터페이스, UseCase, 값 객체(value objects), 도메인 예외로 구성된다.

## Key Files

| File | Description |
|------|-------------|
| `entities/business_day.dart` | 영업일 엔티티 |
| `entities/order.dart` | 주문 엔티티 |
| `entities/order_item.dart` | 주문 항목 엔티티 |
| `entities/menu_item.dart` | 메뉴 항목 엔티티 |
| `entities/seat.dart` | 좌석 엔티티 |
| `entities/credit_account.dart` | 외상 계정 엔티티 |
| `entities/credit_transaction.dart` | 외상 거래 내역 엔티티 |
| `entities/daily_sales_report.dart` | 일일 매출 보고서 엔티티 |
| `repositories/i_order_repository.dart` | 주문 repository 인터페이스 |
| `repositories/i_business_day_repository.dart` | 영업일 repository 인터페이스 |
| `repositories/i_menu_item_repository.dart` | 메뉴 항목 repository 인터페이스 |
| `repositories/i_seat_repository.dart` | 좌석 repository 인터페이스 |
| `repositories/i_credit_account_repository.dart` | 외상 계정 repository 인터페이스 |
| `exceptions/domain_exceptions.dart` | 도메인 예외 클래스 모음 |
| `value_objects/order_status.dart` | `sealed class OrderStatus` |
| `value_objects/payment_type.dart` | 결제 유형 |
| `value_objects/payment_result.dart` | 결제 결과 |
| `value_objects/credit_transaction_type.dart` | 외상 거래 유형 |
| `value_objects/business_day_status.dart` | 영업일 상태 |
| `value_objects/close_result.dart` | 마감 결과 |

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `entities/` | 도메인 엔티티 (순수 Dart 클래스) |
| `repositories/` | 추상 repository 인터페이스 (`abstract interface class`) |
| `usecases/` | 비즈니스 로직 UseCase (see `usecases/AGENTS.md`) |
| `value_objects/` | sealed class, enum 등 값 객체 |
| `exceptions/` | 도메인 예외 (`BusinessDayNotFoundException` 등) |

## For AI Agents

### Working In This Directory
- **Flutter import 절대 금지** — 순수 Dart만 허용
- drift import 금지
- repository 인터페이스: `abstract interface class IXxxRepository` 패턴
- value objects: `sealed class` + exhaustive switch 사용
- 새 엔티티 추가 시 대응하는 repository interface도 함께 작성

### Testing Requirements
- `test/domain/` 에 mockito 기반 단위 테스트 필수
- 구현 전 테스트 먼저 작성 (TDD RED → GREEN)

### Common Patterns
```dart
// repository 인터페이스 패턴
abstract interface class IOrderRepository {
  Future<Order?> getById(String id);
  Future<List<Order>> getByBusinessDay(String businessDayId);
  Future<void> save(Order order);
}

// sealed class 패턴
sealed class OrderStatus { ... }
final class Pending extends OrderStatus { ... }
```

## Dependencies

### Internal
- 없음 (도메인 레이어는 다른 레이어에 의존하지 않음)

### External
- 없음 (순수 Dart)

<!-- MANUAL: -->
