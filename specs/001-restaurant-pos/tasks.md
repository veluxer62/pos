# Tasks: Restaurant POS App

**Input**: Design documents from `/specs/001-restaurant-pos/`
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ contracts/ ✅
**Tech Stack**: Flutter 3.x · Dart 3.x · drift 2.x · flutter_riverpod 2.x · go_router
**Tests**: TDD 필수 (Constitution II — Red→Green→Refactor)

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: 다른 파일, 의존 없음 — 병렬 실행 가능
- **[Story]**: 해당 User Story 레이블 (US1~US5)
- **TDD**: 테스트 태스크는 구현 태스크보다 반드시 먼저 수행하고, 실패(RED)를 확인 후 구현

---

## Phase 1: Setup (프로젝트 초기화)

**Purpose**: Flutter 프로젝트 생성 및 공통 인프라 설정

- [x] T001 Flutter 프로젝트 생성 및 pubspec.yaml에 의존성 추가 (drift, drift_flutter, flutter_riverpod, riverpod_annotation, go_router, uuid, json_annotation) + dev deps (build_runner, drift_dev, riverpod_generator, json_serializable, mockito, build_verify)
- [x] T002 [P] analysis_options.yaml 생성 — strict lint (prefer_final_fields, avoid_dynamic 등) + 커스텀 규칙 설정
- [x] T003 [P] lib/ 디렉토리 구조 생성: domain/{entities,repositories,usecases,value_objects,exceptions}, data/local/{database,daos,repositories}, data/remote/repositories, presentation/{theme,widgets,pages,providers}, core/{di,router,utils}
- [x] T004 [P] test/ 디렉토리 구조 생성: domain/usecases, data/daos, presentation/{pages,widgets}, integration_test/

**Checkpoint**: 프로젝트 구조 준비 완료, `flutter pub get` 통과

---

## Phase 2: Foundational (도메인 레이어 + DB 스키마)

**Purpose**: 모든 User Story가 의존하는 핵심 인프라. 이 Phase 완료 전 US 구현 불가

⚠️ **CRITICAL**: Phase 2 완료 후 `dart run build_runner build --delete-conflicting-outputs` 실행 필수

- [X] T005 [P] 도메인 Value Objects 정의: `lib/domain/value_objects/order_status.dart` (sealed class OrderStatus + exhaustive switch), `payment_type.dart`, `business_day_status.dart`, `credit_transaction_type.dart`
- [X] T006 [P] 도메인 Entity 클래스 8개 정의 (순수 Dart, freezed 없이): `lib/domain/entities/menu_item.dart`, `seat.dart`, `order.dart`, `order_item.dart`, `business_day.dart`, `credit_account.dart`, `credit_transaction.dart`, `daily_sales_report.dart`
- [X] T007 [P] 도메인 예외 클래스 정의: `lib/domain/exceptions/domain_exceptions.dart` — BusinessDayNotFoundException, BusinessDayAlreadyOpenException, InvalidStateTransitionException, OrderNotModifiableException, PendingOrdersExistException, CreditAccountHasBalanceException, MenuItemInUseException, SeatInUseException, DuplicateSeatNumberException
- [X] T008 도메인 Repository 인터페이스 5개 정의: `lib/domain/repositories/i_menu_item_repository.dart`, `i_seat_repository.dart`, `i_order_repository.dart`, `i_business_day_repository.dart`, `i_credit_account_repository.dart` (contracts/ 참조)
- [X] T009 drift 테이블 클래스 8개 정의: `lib/data/local/database/tables.dart` — MenuItems, Seats, BusinessDays, Orders, OrderItems, CreditAccounts, CreditTransactions, DailySalesReports (data-model.md 참조)
- [X] T010 AppDatabase 클래스 생성: `lib/data/local/database/app_database.dart` — `@DriftDatabase(tables=[...])`, MigrationStrategy(onCreate, onUpgrade), `NativeDatabase` 초기화 (build_runner 실행)
- [X] T011 [P] 디자인 시스템 정의: `lib/presentation/theme/app_colors.dart`, `app_spacing.dart`, `app_typography.dart`, `app_theme.dart` — raw hex/pixel 값은 이 파일에만 허용
- [X] T012 [P] 공통 위젯 생성: `lib/presentation/widgets/app_button.dart`, `confirm_dialog.dart`, `app_snack_bar.dart`, `app_error_widget.dart`
- [X] T013 go_router 라우트 정의: `lib/core/router/router.dart` — ShellRoute(홈/외상/보고서/설정), 각 페이지 경로 상수 (`AppRoutes`), 영업일 상태 라우트 가드 stub
- [X] T014 Riverpod DI 설정: `lib/core/di/providers.dart` — `appDatabaseProvider`, 5개 repository provider (LocalXxx 바인딩은 각 Phase에서 완성), `lib/main.dart` ProviderScope + GoRouter 연결

**Checkpoint**: 도메인 레이어 컴파일 통과, drift 코드 생성 완료, 앱 빈 화면 기동 확인

---

## Phase 3: User Story 1 — 주문 접수 및 음식 전달 상태 관리 (P1) 🎯 MVP

**Goal**: 좌석 선택 → 메뉴 선택 → 주문 생성(준비중) → 전달 완료 전환 전체 흐름 동작

**Independent Test**: 시드 데이터(메뉴 3종, 좌석 5석, OPEN 영업일 1개) 투입 후 주문 생성 → 전달 완료 → 취소 흐름을 앱에서 완주. 총액 자동 계산·상태 전이·전달 시각 기록 확인.

### TDD — US1 테스트 먼저 작성 (RED 확인 후 구현)

- [X] T015 [P] [US1] UseCase 단위 테스트: `test/domain/usecases/create_order_use_case_test.dart` — mock IOrderRepository, mock IBusinessDayRepository 사용. 정상 생성·영업일 없음 예외·빈 items 예외 케이스
- [X] T016 [P] [US1] UseCase 단위 테스트: `test/domain/usecases/deliver_order_use_case_test.dart`, `cancel_order_use_case_test.dart` — 상태 전이 성공·잘못된 상태 예외 케이스
- [X] T017 [P] [US1] DAO 통합 테스트(in-memory drift): `test/data/daos/menu_item_dao_test.dart` — findAll(onlyAvailable), findById
- [X] T018 [P] [US1] DAO 통합 테스트: `test/data/daos/seat_dao_test.dart` — findAll, seatNumber unique 검증
- [X] T019 [P] [US1] DAO 통합 테스트: `test/data/daos/business_day_dao_test.dart` — getOpen null/non-null, OPEN 최대 1개 보장
- [X] T020 [P] [US1] DAO 통합 테스트: `test/data/daos/order_dao_test.dart` — create, findByBusinessDay, findActiveOrderBySeat, deliver, cancel, totalAmount 계산

### US1 구현

- [X] T021 [US1] MenuItemDao 구현: `lib/data/local/daos/menu_item_dao.dart` — findAll(onlyAvailable), findById, insert, update, softDelete, watchAll
- [X] T022 [US1] LocalMenuItemRepository 구현: `lib/data/local/repositories/local_menu_item_repository.dart` — IMenuItemRepository 구현
- [X] T023 [US1] SeatDao 구현: `lib/data/local/daos/seat_dao.dart` — findAll, findById, findBySeatNumber, insert, update, delete, watchAll
- [X] T024 [US1] LocalSeatRepository 구현: `lib/data/local/repositories/local_seat_repository.dart` — ISeatRepository 구현
- [X] T025 [US1] BusinessDayDao (기본) 구현: `lib/data/local/daos/business_day_dao.dart` — getOpen, findById (open/close는 Phase 6에서 완성)
- [X] T026 [US1] LocalBusinessDayRepository (기본) 구현: `lib/data/local/repositories/local_business_day_repository.dart` — getOpen, findById, watchOpen
- [X] T027 [US1] OrderDao, OrderItemDao 구현: `lib/data/local/daos/order_dao.dart` — create(+totalAmount 계산), findByBusinessDay, findActiveOrderBySeat, deliver, cancel, addItem, updateItemQuantity, watchByBusinessDay
- [X] T028 [US1] LocalOrderRepository 구현: `lib/data/local/repositories/local_order_repository.dart` — IOrderRepository 중 US1 메서드 (create, findById, findByBusinessDay, findActiveOrderBySeat, deliver, cancel, addItem, updateItemQuantity, watchByBusinessDay)
- [X] T029 [US1] UseCase 구현: `lib/domain/usecases/order/create_order_use_case.dart`, `deliver_order_use_case.dart`, `cancel_order_use_case.dart`
- [X] T030 [US1] 개발용 시드 데이터 유틸: `lib/core/utils/dev_seed.dart` — 메뉴 5종, 좌석 5석, OPEN 영업일 1개 삽입 (debug build only)
- [X] T031 [US1] DI providers 업데이트: `lib/core/di/providers.dart`에 menuItemRepositoryProvider, seatRepositoryProvider, orderRepositoryProvider, businessDayRepositoryProvider 바인딩 추가
- [X] T032 [US1] Riverpod providers: `lib/presentation/providers/order_providers.dart` — activeOrdersBySeatProvider, orderDetailProvider, menuItemListProvider, seatListProvider
- [X] T033 [P] [US1] SeatGridPage 구현: `lib/presentation/pages/order/seat_grid_page.dart` — 번호 기반 그리드, 활성 주문 여부 색상 구분(주문 없음/준비중/전달 완료)
- [X] T034 [P] [US1] SeatGridWidget 구현: `lib/presentation/pages/order/widgets/seat_grid_widget.dart` — 터치 영역 48dp 이상, Semantics 적용
- [X] T035 [US1] CreateOrderPage 구현: `lib/presentation/pages/order/create_order_page.dart` — 메뉴 목록(카테고리 필터), 수량 선택, 총액 실시간 계산, 주문 확정 버튼
- [X] T036 [US1] OrderDetailPage 구현: `lib/presentation/pages/order/order_detail_page.dart` — 주문 항목 목록, 항목 수정/삭제(준비중만), 전달 완료 버튼, 취소 버튼(ConfirmDialog)
- [X] T037 [P] [US1] 위젯 테스트: `test/presentation/pages/order/seat_grid_widget_test.dart` — 주문 상태별 색상 렌더링 확인

**Checkpoint**: US1 독립 완주 가능 — 시드 데이터로 주문 생성 → 전달 완료 → 취소 전체 흐름 동작

---

## Phase 4: User Story 2 — 결제 처리 (즉시 결제 및 외상 결제) (P2)

**Goal**: 전달 완료 주문 → 결제 화면 → 즉시 결제(PAID) 또는 외상 결제(CREDITED) 선택 및 처리, 환불(REFUNDED)

**Independent Test**: US1 완료 후 주문이 DELIVERED 상태에서 즉시 결제·외상 결제 각각 성공, 결제 완료 후 항목 수정 차단, 환불 흐름 동작 확인.

### TDD — US2 테스트 먼저 작성

- [X] T038 [P] [US2] UseCase 단위 테스트: `test/domain/usecases/pay_immediate_use_case_test.dart`, `pay_credit_use_case_test.dart` — DELIVERED→PAID, DELIVERED→CREDITED, 잘못된 상태 예외
- [X] T039 [P] [US2] UseCase 단위 테스트: `test/domain/usecases/refund_order_use_case_test.dart` — PAID→REFUNDED, 잘못된 상태 예외

### US2 구현

- [X] T040 [US2] LocalOrderRepository 확장: `lib/data/local/repositories/local_order_repository.dart`에 payImmediate, payCredit, refund 메서드 추가
- [X] T041 [US2] UseCase 구현: `lib/domain/usecases/order/pay_immediate_use_case.dart`, `pay_credit_use_case.dart`, `refund_order_use_case.dart`
- [X] T042 [US2] CreditAccountDao (최소) 구현: `lib/data/local/daos/credit_account_dao.dart` — findAll(hasBalance), findById (전체 CRUD는 Phase 5에서 완성)
- [X] T043 [US2] LocalCreditAccountRepository (최소) 구현: `lib/data/local/repositories/local_credit_account_repository.dart` — findAll, findById (charge는 payCredit 처리 시 사용)
- [X] T044 [US2] DI providers 업데이트: creditAccountRepositoryProvider 바인딩 추가
- [X] T045 [US2] PaymentPage 구현: `lib/presentation/pages/payment/payment_page.dart` — 결제 금액·항목 표시, 즉시 결제 / 외상 결제 선택 버튼
- [X] T046 [US2] CreditAccountSelectWidget 구현: `lib/presentation/pages/payment/widgets/credit_account_select_widget.dart` — 계좌 목록(잔액 포함), 신규 등록 인라인 입력
- [X] T047 [P] [US2] 위젯 테스트: `test/presentation/pages/payment/payment_page_test.dart` — 결제 금액 표시, 버튼 상태 검증

**Checkpoint**: US1+US2 독립 동작 — 주문 생성→전달→결제(즉시/외상)→환불 전 흐름 완주

---

## Phase 5: User Story 3 — 외상 장부 관리 및 대금 납부 (P3)

**Goal**: 외상 계좌 등록·조회·납부, 거래 이력 확인, 계좌 삭제(잔액 0만)

**Independent Test**: 외상 계좌 등록 → US2 외상 결제로 잔액 발생 → 납부 입력 → 잔액 차감 확인, 과납 처리(잔액 0), 계좌 목록 잔액 내림차순 정렬 확인.

### TDD — US3 테스트 먼저 작성

- [X] T048 [P] [US3] UseCase 단위 테스트: `test/domain/usecases/pay_credit_account_use_case_test.dart` — 정상 납부, 과납(잔액 0 처리), 계좌 없음 예외
- [X] T049 [P] [US3] DAO 통합 테스트: `test/data/daos/credit_account_dao_test.dart` — charge 원자성(balance 증가 + transaction 생성), pay(balance 감소), 과납 처리, 잔액 있는 계좌 삭제 차단

### US3 구현

- [X] T050 [US3] CreditAccountDao 확장: `lib/data/local/daos/credit_account_dao.dart`에 create, charge, pay, delete, getTransactions, watchAll 추가 (drift `transaction()` 블록으로 원자적 처리)
- [X] T051 [US3] CreditTransactionDao 구현: `lib/data/local/daos/credit_transaction_dao.dart` — findByAccount(type, limit, offset)
- [X] T052 [US3] LocalCreditAccountRepository 확장: `lib/data/local/repositories/local_credit_account_repository.dart`에 create, charge, pay, delete, getTransactions, watchAll 추가
- [X] T053 [US3] UseCase 구현: `lib/domain/usecases/credit/create_credit_account_use_case.dart`, `pay_credit_account_use_case.dart` (과납 처리 포함)
- [X] T054 [US3] Riverpod providers: `lib/presentation/providers/credit_account_providers.dart` — creditAccountListProvider, creditAccountDetailProvider
- [X] T055 [US3] CreditAccountListPage 구현: `lib/presentation/pages/credit/credit_account_list_page.dart` — 잔액 내림차순, 완납(잔액 0) 계좌 구분 표시
- [X] T056 [US3] CreditAccountDetailPage 구현: `lib/presentation/pages/credit/credit_account_detail_page.dart` — 잔액·거래 이력(시간 역순), 납부 버튼
- [X] T057 [US3] CreditPaymentDialog 구현: `lib/presentation/pages/credit/widgets/credit_payment_dialog.dart` — 납부 금액 입력, 과납 시 경고(잔액 0 처리 안내), ConfirmDialog 연동

**Checkpoint**: US3 독립 동작 — 외상 계좌 CRUD, 납부 흐름, 거래 이력 조회 완주

---

## Phase 6: User Story 4 — 영업 일과 관리 및 일일 매출 보고서 조회 (P4)

**Goal**: 영업 시작(OPEN)/마감(CLOSED) UI, 마감 시 DailySalesReport 원자 생성, 보고서 조회(당일·과거), 기간별 집계

**Independent Test**: 영업 시작 → 주문 다수 생성·결제·취소 → 영업 마감(미처리 주문 경고·강제 마감 확인) → 일일 매출 보고서에서 확정 매출·외상 발생액·메뉴별·시간대별 데이터 검증.

### TDD — US4 테스트 먼저 작성

- [X] T058 [P] [US4] UseCase 단위 테스트: `test/domain/usecases/open_business_day_use_case_test.dart` — 정상 개시, 이미 OPEN 예외
- [X] T059 [P] [US4] UseCase 단위 테스트: `test/domain/usecases/close_business_day_use_case_test.dart` — 정상 마감(보고서 생성 검증), 미처리 주문 예외, forceClose 마감, 집계 수치(totalRevenue, creditedAmount, 취소/환불 카운트) 정확성
- [X] T060 [P] [US4] DAO 통합 테스트: `test/data/daos/business_day_dao_test.dart` — open/close 원자성, getReport, OPEN 중복 방지

### US4 구현

- [X] T061 [US4] BusinessDayDao 완성: `lib/data/local/daos/business_day_dao.dart`에 open, close(+CANCELLED 처리), findAll, getReport, getReports 추가 (drift `transaction()` 블록)
- [X] T062 [US4] DailySalesReport 집계 로직 구현: close() 내부에서 PAID 합산(totalRevenue), CREDITED 합산(creditedAmount), 취소/환불 카운트, menuSummaryJson(`List<MenuSalesItem>`), hourlySummaryJson(`List<HourlySalesItem>`) 계산
- [X] T063 [US4] LocalBusinessDayRepository 완성: `lib/data/local/repositories/local_business_day_repository.dart`에 open, close, findAll, getReport, getReports 추가
- [X] T064 [US4] UseCase 구현: `lib/domain/usecases/business_day/open_business_day_use_case.dart`, `close_business_day_use_case.dart`
- [ ] T065 [US4] Riverpod providers: `lib/presentation/providers/business_day_providers.dart` — openBusinessDayProvider, businessDayReportProvider
- [ ] T066 [US4] BusinessDayPage 구현: `lib/presentation/pages/business_day/business_day_page.dart` — 영업 상태 표시, 영업 시작/마감 버튼
- [ ] T067 [US4] CloseBusinessDayDialog 구현: `lib/presentation/pages/business_day/widgets/close_business_day_dialog.dart` — 미처리 주문(준비중 N건, 전달 완료 N건) 경고, 강제 마감 확인
- [ ] T068 [US4] DailySalesReportPage 구현: `lib/presentation/pages/business_day/daily_sales_report_page.dart` — 확정 매출, 외상 발생액(미수금), 주문 건수, 취소·환불 건수, 메뉴별 판매 수량, 시간대별 분포
- [ ] T069 [P] [US4] SalesHistoryPage 구현: `lib/presentation/pages/business_day/sales_history_page.dart` — 기간 필터, 영업일별 매출 목록, 베스트셀러 메뉴
- [ ] T070 [US4] go_router 라우트 가드 완성: `lib/core/router/router.dart` — OPEN 영업일 없을 때 주문 생성 차단 리다이렉트

**Checkpoint**: US4 독립 동작 — 영업 시작~마감~보고서 생성 전 흐름, 라우트 가드 동작

---

## Phase 7: User Story 5 — 메뉴 및 좌석 설정 관리 (P5)

**Goal**: 메뉴(이름·가격·카테고리·판매가능여부) 및 좌석(번호·수용인원) CRUD 설정 UI

**Independent Test**: 신규 메뉴 등록 후 주문 화면에 즉시 반영, 활성 주문 있는 메뉴 삭제 시도 시 soft-disable 안내, 좌석 수용 인원 변경 후 진행 중 주문에 영향 없음 확인.

### TDD — US5 테스트 먼저 작성

- [ ] T071 [P] [US5] UseCase 단위 테스트: `test/domain/usecases/menu_item/create_menu_item_use_case_test.dart`, `update_menu_item_use_case_test.dart`, `delete_menu_item_use_case_test.dart` — 정상 CRUD, 활성 주문 참조 시 예외
- [ ] T072 [P] [US5] UseCase 단위 테스트: `test/domain/usecases/seat/create_seat_use_case_test.dart`, `delete_seat_use_case_test.dart` — 중복 번호 예외, 활성 주문 연결 시 삭제 예외

### US5 구현

- [ ] T073 [US5] UseCase 구현: `lib/domain/usecases/menu_item/create_menu_item_use_case.dart`, `update_menu_item_use_case.dart`, `delete_menu_item_use_case.dart`
- [ ] T074 [US5] UseCase 구현: `lib/domain/usecases/seat/create_seat_use_case.dart`, `update_seat_use_case.dart`, `delete_seat_use_case.dart`
- [ ] T075 [US5] SettingsPage 구현: `lib/presentation/pages/settings/settings_page.dart` — 메뉴 관리·좌석 관리 탭
- [ ] T076 [US5] MenuItemListPage 구현: `lib/presentation/pages/settings/menu_item_list_page.dart` — 메뉴 목록, 추가·수정·삭제(soft-disable 안내)
- [ ] T077 [US5] MenuItemFormDialog 구현: `lib/presentation/pages/settings/widgets/menu_item_form_dialog.dart` — 이름·가격(KRW)·카테고리 입력 폼 (이미지 없음)
- [ ] T078 [US5] SeatListPage 구현: `lib/presentation/pages/settings/seat_list_page.dart` — 좌석 목록, 추가·수정·삭제
- [ ] T079 [US5] SeatFormDialog 구현: `lib/presentation/pages/settings/widgets/seat_form_dialog.dart` — 좌석 번호·수용 인원 입력 폼

**Checkpoint**: US5 독립 동작 — 메뉴·좌석 CRUD 완주, 변경 사항이 주문 화면에 즉시 반영

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: 다중 User Story에 걸친 개선 사항, 품질 게이트

- [ ] T080 [P] KRW 금액 포맷터(`₩1,000`) 및 날짜 유틸 구현: `lib/core/utils/currency_formatter.dart`, `date_formatter.dart`
- [ ] T081 [P] 주요 UI에 Semantics 접근성 래퍼 추가 (버튼·그리드·다이얼로그 — 최소 터치 영역 48dp 확인)
- [ ] T082 원격 stub 구조 생성: `lib/data/remote/repositories/` 디렉토리 + README (백엔드 전환 시 구현 위치)
- [ ] T083 개발용 시드 데이터(`dev_seed.dart`) release build에서 제외되도록 빌드 플래그 처리
- [ ] T084 [P] 통합 테스트 작성: `integration_test/us1_order_flow_test.dart` — 영업 시작 → 주문 생성 → 전달 완료 시나리오
- [ ] T085 [P] 통합 테스트 작성: `integration_test/us2_payment_flow_test.dart` — 즉시 결제 + 외상 결제 시나리오
- [ ] T086 `flutter test --coverage` 실행 → domain + data 레이어 80% 이상 확인, 미달 파일 보완
- [ ] T087 `dart analyze` zero warnings 확인, `dart format --check .` 통과

---

## Dependencies & Execution Order

### Phase 의존 관계

- **Phase 1 (Setup)**: 즉시 시작 가능
- **Phase 2 (Foundational)**: Phase 1 완료 후 — 모든 US 차단
- **Phase 3~7 (US1~US5)**: Phase 2 완료 후 우선순위 순 진행
  - US2는 US1의 Order 데이터 레이어를 재사용하므로 US1 완료 후 시작 권장
  - US3은 US2의 외상 결제 흐름이 선행되어야 테스트 데이터 생성 가능
  - US4는 단독 실행 가능하나 보고서 집계 검증에 US1~US3 데이터 필요
  - US5는 Phase 2 이후 어느 시점에도 독립 진행 가능
- **Phase 8 (Polish)**: 원하는 US 완료 후 진행

### User Story 의존 관계 요약

```
Phase 2 완료
    ├── US5 (P5) — 독립 가능 (메뉴·좌석 CRUD)
    └── US1 (P1) → US2 (P2) → US3 (P3)
                ↓
            US4 (P4) — US1~US3 데이터 없이도 구조 구현 가능, 집계 검증에만 의존
```

### US 내부 순서

> 테스트(TDD RED) → DAO → Repository → UseCase → Provider → UI → 위젯 테스트

---

## Parallel Execution Examples

### Phase 2 병렬 실행

```
동시 실행 가능:
  T005 Value Objects
  T006 Domain Entities
  T007 Domain Exceptions
  T011 Design System
  T012 Common Widgets
```

### Phase 3 (US1) 병렬 실행

```
1단계 — TDD (동시 작성):
  T015 CreateOrder UseCase 테스트
  T016 Deliver/Cancel UseCase 테스트
  T017 MenuItemDao 테스트
  T018 SeatDao 테스트
  T019 BusinessDayDao 테스트
  T020 OrderDao 테스트

2단계 — DAO 구현 (동시 가능):
  T021 MenuItemDao
  T023 SeatDao
  T025 BusinessDayDao

3단계 — UI (동시 가능, DAO 완료 후):
  T033 SeatGridPage
  T034 SeatGridWidget
```

---

## Implementation Strategy

### MVP First (US1만)

1. Phase 1: Setup 완료
2. Phase 2: Foundational 완료 (`dart run build_runner build`)
3. Phase 3: US1 완료
4. **STOP & VALIDATE**: 시드 데이터로 주문 생성→전달→취소 완주
5. 데모 가능

### Incremental Delivery

1. Setup + Foundational → 앱 기동 확인
2. **US1** → 주문 접수·전달 관리 (MVP)
3. **US2** → 결제 처리
4. **US3** → 외상 장부
5. **US4** → 영업 시작·마감·보고서
6. **US5** → 설정 UI
7. Polish → 품질 게이트

---

## Notes

- **build_runner**: drift 테이블/쿼리·Riverpod provider 코드 변경 시 `dart run build_runner build --delete-conflicting-outputs` 재실행
- **TDD**: 각 Phase 테스트 태스크는 반드시 먼저 작성하고 RED(실패) 확인 후 구현 태스크 진행
- `[P]` 태스크 = 다른 파일, 의존 없음 — 병렬 실행 가능
- `[US?]` 레이블 = 해당 User Story 추적용
- 각 Phase Checkpoint에서 독립 검증 후 다음 Phase 진행
- 커밋은 논리적 단위(태스크 또는 Checkpoint)마다 수행
