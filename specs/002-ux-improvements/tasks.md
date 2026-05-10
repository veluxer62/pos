---
description: "Task list for UX 개선 및 버그 수정"
---

# Tasks: UX 개선 및 버그 수정 (002-ux-improvements)

**Input**: Design documents from `/specs/002-ux-improvements/`
**Branch**: `002-ux-improvements`
**Plan**: [plan.md](./plan.md) | **Spec**: [spec.md](./spec.md)

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 병렬 실행 가능 (다른 파일, 완료된 선행 작업 없음)
- **[US0~US4]**: 해당 User Story 소속 태스크
- 각 태스크에 정확한 파일 경로 포함

---

## Phase 1: Setup

**Purpose**: 신규 패키지 추가 및 빌드 환경 준비

- [x] T001 `pubspec.yaml`에 `share_plus: ^10.0.0` 의존성 추가 후 `flutter pub get` 실행
- [x] T002 `pubspec.yaml`에 `path_provider` 의존성 확인 — 없으면 `^2.1.0` 추가

**Checkpoint**: `flutter pub get` 성공, `dart analyze` zero warnings 유지

---

## Phase 2: User Story 0 — 주문 항목 표시 버그 수정 (Priority: P0) 🚨 즉시 수정

**Goal**: `order_detail_page.dart:57`의 `items: const []` 하드코딩을 제거하고 DB에서 조회한 실제 항목을 표시

**Independent Test**: 메뉴 포함 주문 생성 후 주문 상세 화면을 열면 `find.text('김치찌개')` 등 항목이 표시됨

- [x] T003 [US0] `lib/data/local/daos/order_dao.dart`에 `watchItemsByOrder(String orderId)` Stream 메서드 추가 — `findItemsByOrder` 와 동일 쿼리이나 `.watch()` 기반 Stream 반환
- [x] T004 [US0] `lib/presentation/providers/order_providers.dart`에 `orderItemsProvider(String orderId)` StreamProvider 추가 — `OrderDao.watchItemsByOrder` 호출
- [x] T005 [US0] `lib/presentation/pages/order/order_detail_page.dart:57` 수정 — `_OrderItemList(items: const [], ...)` → `ref.watch(orderItemsProvider(orderId))` 결과 전달. `AsyncValue.when`으로 로딩/에러/데이터 처리
- [x] T006 [P] [US0] `test/presentation/pages/order/order_detail_page_test.dart` 위젯 테스트 신규 작성 — 항목 포함 주문 seed 후 `OrderDetailPage` 렌더링, `find.text('김치찌개')` 검증; 빈 항목 주문 시 "주문 항목 없음" 텍스트 검증

**Checkpoint**: `flutter test test/presentation/pages/order/order_detail_page_test.dart` 통과

---

## Phase 3: User Story 1 — 60대 접근성 개선 (Priority: P1)

**Goal**: 폰트 크기 18/20sp, 명시적 삭제 버튼, 취소 경고 강화, 한국어 에러 메시지

**Independent Test**: 메뉴 설정 화면에서 `find.byIcon(Icons.delete_outline)` 발견; `AppTypography.priceStyle.fontSize == 20.0`

- [x] T007 [US1] `lib/presentation/theme/app_typography.dart` 수정 — `priceStyle` TextStyle 신규 추가 (fontSize: 20, fontWeight: FontWeight.bold); `bodyLarge` fontSize가 18 미만이면 18로 업데이트
- [x] T008 [P] [US1] `lib/presentation/pages/order/create_order_page.dart` 수정 — 메뉴 카드 내 금액 텍스트에 `AppTypography.priceStyle` 적용
- [x] T009 [P] [US1] `lib/presentation/pages/payment/payment_page.dart` 수정 — 결제 금액 표시 텍스트에 `AppTypography.priceStyle` 적용
- [x] T010 [P] [US1] `lib/presentation/pages/settings/menu_settings_page.dart` 수정 — 각 메뉴 항목 ListTile에 `trailing: IconButton(icon: Icon(Icons.delete_outline), onPressed: () => _confirmDelete(context, item))` 추가; 기존 롱프레스 핸들러 제거
- [x] T011 [P] [US1] `lib/presentation/pages/settings/seat_settings_page.dart` 수정 — T010과 동일 패턴으로 명시적 삭제 버튼 추가
- [x] T012 [US1] `lib/presentation/pages/order/order_detail_page.dart` 수정 — `_confirmCancel` 다이얼로그 메시지를 "주문을 취소하면 되돌릴 수 없습니다. 계속하시겠습니까?"로 변경
- [x] T013 [US1] `lib/presentation/utils/error_message_mapper.dart` 신규 작성 — 도메인 exception 타입별 한국어 메시지 반환 `mapToUserMessage(Object error)` 함수. `BusinessDayNotFoundException`, `OrderNotEditableException`, `MenuNotAvailableException`, `MinimumOrderItemException` 각각 매핑; 미등록 exception은 기본 메시지 반환
- [x] T014 [P] [US1] `lib/presentation/widgets/app_error_widget.dart` 수정 — `message: e.toString()` 대신 `message: errorMessageMapper.mapToUserMessage(e)` 적용; `error_message_mapper.dart` import 추가
- [x] T015 [P] [US1] `test/presentation/utils/error_message_mapper_test.dart` 신규 작성 — 각 exception 타입 → 한국어 메시지 매핑 단위 테스트

**Checkpoint**: `flutter test test/presentation/` 통과; 설정 화면에서 삭제 아이콘 버튼 표시 확인

---

## Phase 4: User Story 2 — PENDING 주문 항목 수정 기능 (Priority: P2)

**Goal**: PENDING 주문에서 항목 추가/삭제, 품절 메뉴 차단

**Independent Test**: PENDING 주문에 항목 추가 후 총액 재계산; DELIVERED 주문에서 편집 버튼 숨김

**⚠️ TDD 필수**: 테스트 먼저 작성(RED) → UseCase 구현(GREEN) → 리팩토링 순서 준수

- [x] T016 [US2] `lib/domain/exceptions/order_not_editable_exception.dart` 신규 작성 — `class OrderNotEditableException implements Exception { final String orderId; final String currentStatus; }`
- [x] T017 [P] [US2] `lib/domain/exceptions/menu_not_available_exception.dart` 신규 작성 — `class MenuNotAvailableException implements Exception { final String menuItemId; }`
- [x] T018 [P] [US2] `lib/domain/exceptions/minimum_order_item_exception.dart` 신규 작성 — `class MinimumOrderItemException implements Exception { final String orderId; }`
- [x] T019 [US2] `test/domain/usecases/order/add_order_item_use_case_test.dart` 신규 작성 (RED) — PENDING 주문 항목 추가 성공; DELIVERED 주문 시도 → `OrderNotEditableException`; 품절 메뉴 시도 → `MenuNotAvailableException`; quantity < 1 → `ArgumentError` 케이스 포함
- [x] T020 [P] [US2] `test/domain/usecases/order/remove_order_item_use_case_test.dart` 신규 작성 (RED) — PENDING 주문 항목 삭제 성공; 마지막 항목 삭제 시도 → `MinimumOrderItemException`; DELIVERED 주문 시도 → `OrderNotEditableException` 케이스 포함
- [x] T021 [US2] `lib/data/local/daos/order_dao.dart`에 `addItem()` 메서드 추가 — transaction 내에서 OrderItem insert + order.totalAmount 재계산 업데이트
- [x] T022 [P] [US2] `lib/data/local/daos/order_dao.dart`에 `removeItem()` 메서드 추가 — transaction 내에서 OrderItem delete + order.totalAmount 재계산 업데이트
- [x] T023 [US2] `lib/domain/usecases/order/add_order_item_use_case.dart` 신규 구현 (GREEN) — T019 테스트 통과 목표. PENDING 검증 → MenuItem 조회 + isAvailable 검증 → DAO.addItem 호출
- [x] T024 [US2] `lib/domain/usecases/order/remove_order_item_use_case.dart` 신규 구현 (GREEN) — T020 테스트 통과 목표. PENDING 검증 → 최소 항목 수 검증 → DAO.removeItem 호출
- [x] T025 [P] [US2] `test/data/daos/order_dao_test.dart`에 `addItem()`/`removeItem()` 통합 테스트 추가 — NativeDatabase.memory() 사용, 항목 추가 후 totalAmount 재계산 검증
- [x] T026 [US2] `lib/presentation/pages/order/order_detail_page.dart` 수정 — PENDING 상태일 때 항목 목록 하단에 "+ 메뉴 추가" 버튼 표시; 각 항목 옆 삭제 버튼(PENDING만); DELIVERED/PAID 상태 시 편집 버튼 숨김
- [x] T027 [US2] `lib/presentation/pages/order/create_order_page.dart` 수정 — `isAvailable == false` 메뉴 카드에 `Opacity(opacity: 0.4)` 적용; 탭 시 AddItem 대신 `AppSnackBar.show(context, '현재 판매하지 않는 메뉴입니다.')` 표시

**Checkpoint**: `flutter test test/domain/usecases/order/` 통과; PENDING 주문 항목 추가 후 totalAmount 재계산 확인

---

## Phase 5: User Story 3 — 외상 계좌 데이터 강화 (Priority: P3)

**Goal**: CreditAccount phone/note 필드 추가, drift 마이그레이션, 연락처 UI, 거래→주문 딥링크

**Independent Test**: CreditAccount 등록 시 phone/note 저장·조회; 기존 계좌 마이그레이션 후 데이터 보존

**⚠️ 주의**: T029(테이블 변경) 후 반드시 `dart run build_runner build --delete-conflicting-outputs` 실행

- [x] T028 [US3] `lib/domain/entities/credit_account.dart` 수정 — `phone`, `note` nullable String 필드 추가; `copyWith` 메서드에 해당 파라미터 추가
- [x] T029 [US3] `lib/data/local/database/tables.dart`(또는 CreditAccounts 정의 파일) 수정 — `CreditAccountsTable`에 `TextColumn get phone => text().nullable()();`, `TextColumn get note => text().nullable()();` 추가
- [x] T030 [US3] `lib/data/local/database/app_database.dart` 수정 — `schemaVersion` 1 → 2; `MigrationStrategy.onUpgrade`에 `if (from < 2) { await m.addColumn(creditAccounts, creditAccounts.phone); await m.addColumn(creditAccounts, creditAccounts.note); }` 추가
- [x] T031 [US3] `dart run build_runner build --delete-conflicting-outputs` 실행 — drift 코드 생성 파일 재생성 (`app_database.g.dart`)
- [x] T032 [US3] `test/data/migrations/migration_v2_test.dart` 신규 작성 — schemaVersion 1 DB 생성 후 버전 2로 업그레이드, 기존 계좌 데이터(phone=null, note=null) 정상 조회 검증; `NativeDatabase.memory()` 사용
- [x] T033 [P] [US3] `lib/data/local/daos/credit_account_dao.dart` 수정 — `create()` 메서드에 `phone`, `note` optional 파라미터 추가; `_rowToEntity()`, `CreditAccountsCompanion` 매핑에 phone/note 포함
- [x] T034 [P] [US3] `lib/presentation/pages/credit/credit_account_form_page.dart` 수정 — 이름 필드 아래에 연락처(선택), 메모(선택) TextField 추가; 저장 시 phone/note 포함
- [x] T035 [US3] `lib/presentation/pages/credit/credit_account_detail_page.dart` 수정 — 계좌 상세 상단에 phone/note 표시 (값 없으면 해당 행 숨김); 거래 이력 "외상 발생" 항목 탭 시 `context.push(AppRoutes.orderDetailPath(transaction.orderId))` 네비게이션 추가; 연결 주문 없을 경우 SnackBar 안내

**Checkpoint**: `flutter test test/data/migrations/migration_v2_test.dart` 통과; 외상 계좌 등록 시 phone 저장 확인

---

## Phase 6: User Story 4 — 성능 및 데이터 백업 (Priority: P4)

**Goal**: SeatGridPage N+1 → batch 쿼리 1회, JSON 내보내기 + Share

**Independent Test**: `watchAllWithActiveOrders()` 호출이 1회만 발생; Share sheet 표시 확인

- [x] T036 [US4] `lib/domain/value_objects/seat_with_active_order.dart` 신규 작성 — `class SeatWithActiveOrder { final Seat seat; final Order? activeOrder; }`
- [x] T037 [US4] `lib/data/local/daos/seat_dao.dart`에 `watchAllWithActiveOrders()` 메서드 추가 — seats LEFT JOIN orders (status IN pending/delivered) 단일 쿼리; `Stream<List<SeatWithActiveOrder>>` 반환; seatNumber 오름차순 정렬
- [x] T038 [P] [US4] `test/data/daos/seat_dao_test.dart`에 `watchAllWithActiveOrders()` 통합 테스트 추가 — 좌석 3개 + 활성주문 2개 seed 후 반환값 검증; NativeDatabase.memory() 사용
- [x] T039 [US4] `lib/presentation/providers/seat_providers.dart`(또는 신규 파일)에 `seatsWithActiveOrdersProvider` StreamProvider 추가 — `SeatDao.watchAllWithActiveOrders()` 호출
- [x] T040 [US4] `lib/presentation/pages/order/seat_grid_page.dart` 수정 — `ref.watch(activeOrderBySeatProvider(seat.id))` N+1 패턴 → `ref.watch(seatsWithActiveOrdersProvider)` 단일 watch로 교체; 각 SeatCard에 `SeatWithActiveOrder`에서 order 전달
- [x] T041 [P] [US4] `lib/domain/usecases/export_data_use_case.dart` 신규 작성 — 전체 BusinessDay·Order·CreditTransaction 데이터 조회 후 JSON 직렬화; `Future<String> execute()` → 임시 파일 경로 반환
- [x] T042 [US4] `lib/presentation/pages/settings/settings_page.dart` 수정 — "데이터 내보내기" ListTile 버튼 추가; 탭 시 `ExportDataUseCase.execute()` 호출 후 `Share.shareXFiles([XFile(path)])` 실행; 파일명 `pos_backup_YYYYMMDD.json`

**Checkpoint**: `flutter test test/data/daos/seat_dao_test.dart` 통과; `seatsWithActiveOrdersProvider` 사용 후 DB 쿼리 1회 확인

---

## Phase 7: Polish & Quality Gate

**Purpose**: 전체 테스트 통과, zero warnings, 회귀 방지

- [x] T043 `dart analyze` 실행 — zero warnings 확인; 발견된 경고 즉시 수정
- [x] T044 `flutter test` 실행 — 기존 + 신규 테스트 전체 통과 확인
- [x] T045 `flutter test --coverage` 실행 — domain + data 레이어 80% 이상 유지 확인
- [x] T046 `dart format .` 실행 — 전체 코드 포맷 적용

---

## Dependencies (완료 순서)

```
T001, T002 (Setup)
  ↓
T003 → T004 → T005 → T006 (US0 — 버그 수정, 즉시)
  ↓
T007~T015 (US1 — 접근성, US0과 병렬 가능)
  ↓
T016~T018 → T019, T020 (RED) → T021, T022 → T023, T024 (GREEN) → T025~T027 (US2)
  ↓
T028 → T029 → T030 → T031 (build_runner) → T032~T035 (US3 — 마이그레이션 선행 필수)
  ↓
T036 → T037 → T038~T042 (US4 — US0~US3과 독립적)
  ↓
T043~T046 (Polish)
```

**병렬 실행 기회**:
- US1(T007~T015)은 US0(T003~T006) 완료 후 US2, US3, US4와 동시 진행 가능
- US4(T036~T042)는 US2, US3과 완전 독립 — 동시 진행 가능
- [P] 마킹된 태스크는 동일 Phase 내에서 병렬 실행 가능

---

## 구현 전략

**MVP**: US0(P0 버그 수정) 단독으로도 즉시 가치 전달 가능 — T001~T006만으로 배포 가능

**단계별 증분 전달**:
1. US0 (T001~T006): Critical Bug — 즉시 수정 후 배포
2. US1 (T007~T015): 접근성 개선 — 독립 배포 가능
3. US2 (T016~T027): PENDING 항목 편집 — TDD 포함
4. US3 (T028~T035): 외상 계좌 강화 — 마이그레이션 포함
5. US4 (T036~T042): 성능·백업 — 마지막 단계

**총 태스크 수**: 46개 (T001~T046)

| Phase | US | 태스크 수 | 병렬 가능 |
|-------|----|----------|----------|
| Setup | - | 2 | - |
| US0 — 버그 수정 | US0 | 4 | 1 |
| 접근성 | US1 | 9 | 6 |
| PENDING 항목 수정 | US2 | 12 | 4 |
| 외상 계좌 강화 | US3 | 8 | 2 |
| 성능·백업 | US4 | 7 | 2 |
| Polish | - | 4 | - |
