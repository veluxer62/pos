# Remote Repository Implementations

백엔드 연동 시 이 디렉토리에 HTTP 기반 repository 구현체를 추가한다.

## 전환 방법

`lib/core/di/providers.dart`에서 각 repository provider의 반환값을
`LocalXxxRepository` → `RemoteXxxRepository`로 교체하면 된다.
domain·presentation 레이어는 변경이 필요하지 않다.

## 구현 대상

- `remote_menu_item_repository.dart` → `IMenuItemRepository`
- `remote_seat_repository.dart` → `ISeatRepository`
- `remote_order_repository.dart` → `IOrderRepository`
- `remote_business_day_repository.dart` → `IBusinessDayRepository`
- `remote_credit_account_repository.dart` → `ICreditAccountRepository`
