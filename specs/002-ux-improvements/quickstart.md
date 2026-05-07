# Quickstart: 002-ux-improvements 구현 가이드

**Branch**: `002-ux-improvements`
**Plan**: [plan.md](./plan.md)

---

## 구현 순서 및 시작점

### Phase 0 — Critical Bug Fix (P0) — 즉시 시작 가능

```bash
# 1. order_detail_page.dart 버그 수정
# lib/presentation/pages/order/order_detail_page.dart:57
# _OrderItemList(items: const [], ...) → provider로 실제 items 연결

# 2. OrderDao에 watchItemsByOrder 추가
# lib/data/local/daos/order_dao.dart

# 3. order_providers.dart에 orderItemsProvider 추가
# lib/presentation/providers/order_providers.dart

# 4. 위젯 테스트 작성
# test/presentation/pages/order/order_detail_page_test.dart
```

**검증**:
```bash
flutter test test/presentation/pages/order/order_detail_page_test.dart
dart analyze
```

---

### Phase 1 — 접근성 개선

```bash
# 폰트 토큰 추가
# lib/presentation/theme/app_typography.dart
# → priceStyle (20sp bold), bodyLarge 18sp 확인

# 설정 화면 삭제 버튼 명시화
# lib/presentation/pages/settings/menu_settings_page.dart
# lib/presentation/pages/settings/seat_settings_page.dart

# 에러 메시지 매핑 유틸 신규 작성
# lib/presentation/utils/error_message_mapper.dart
```

---

### Phase 2 — PENDING 주문 항목 수정 (TDD 필수)

```bash
# 테스트 먼저 작성 (RED)
# test/domain/usecases/order/add_order_item_use_case_test.dart
# test/domain/usecases/order/remove_order_item_use_case_test.dart

# UseCase 구현 (GREEN)
# lib/domain/usecases/order/add_order_item_use_case.dart
# lib/domain/usecases/order/remove_order_item_use_case.dart

# DAO 메서드 추가
# lib/data/local/daos/order_dao.dart → addItem(), removeItem()

# 신규 예외 클래스 추가
# lib/domain/exceptions/ → order_not_editable_exception.dart
#                         → menu_not_available_exception.dart
#                         → minimum_order_item_exception.dart
```

---

### Phase 3 — 외상 계좌 강화

```bash
# 1. CreditAccount 엔티티 phone/note 필드 추가
# lib/domain/entities/credit_account.dart

# 2. CreditAccounts 테이블 컬럼 추가
# lib/data/local/database/tables.dart (또는 app_database.dart)

# 3. 마이그레이션 스크립트 — schemaVersion 1 → 2
# lib/data/local/database/app_database.dart

# 4. build_runner 재실행 (drift 스키마 변경 후 필수)
dart run build_runner build --delete-conflicting-outputs

# 5. 마이그레이션 테스트 작성
# test/data/migrations/migration_v2_test.dart

# 6. UI 업데이트
# lib/presentation/pages/credit/credit_account_form_page.dart
# lib/presentation/pages/credit/credit_account_detail_page.dart
```

---

### Phase 4 — 성능 및 백업

```bash
# 1. SeatWithActiveOrder VO 신규 작성
# lib/domain/value_objects/seat_with_active_order.dart

# 2. SeatDao.watchAllWithActiveOrders() 추가
# lib/data/local/daos/seat_dao.dart

# 3. seatsWithActiveOrdersProvider 추가
# lib/presentation/providers/seat_providers.dart (또는 신규)

# 4. SeatGridPage N+1 → batch 교체
# lib/presentation/pages/order/seat_grid_page.dart

# 5. share_plus 패키지 추가
# pubspec.yaml → share_plus: ^10.0.0
flutter pub get

# 6. ExportDataUseCase 구현
# lib/domain/usecases/export_data_use_case.dart

# 7. 설정 화면 내보내기 버튼 추가
# lib/presentation/pages/settings/settings_page.dart
```

---

## 핵심 규칙 (Constitution)

1. **TDD**: Phase 2 UseCase는 반드시 테스트 먼저 작성 후 구현
2. **build_runner**: Phase 3에서 테이블 변경 후 반드시 재실행
3. **dart analyze**: 각 Phase 완료 후 zero warnings 확인
4. **기존 테스트 유지**: `flutter test` 실행하여 회귀 없음 확인

## 의존성 변경

```yaml
# pubspec.yaml에 추가할 항목
dependencies:
  share_plus: ^10.0.0
```

`path_provider` 이미 포함 여부 확인 후 없으면 추가:
```bash
grep "path_provider" pubspec.yaml
```
