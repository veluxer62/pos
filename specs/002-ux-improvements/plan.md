# Implementation Plan: UX 개선 및 버그 수정

**Branch**: `002-ux-improvements` | **Date**: 2026-05-07 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-ux-improvements/spec.md`

## Summary

5관점 분석(사용성·독창성·기능성·유용성·지속가능성) 결과를 반영한 12개 개선 항목을 구현한다.
P0 Critical Bug(주문 항목 미표시), P1 60대 접근성(폰트·삭제UI·에러메시지), P2 PENDING 주문 항목 수정,
P3 외상 계좌 데이터 강화(연락처·메모·딥링크), P4 성능(N+1 제거)·백업(JSON 내보내기) 순으로 진행한다.
CreditAccount 스키마 변경을 위한 drift 마이그레이션이 포함된다.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.22+
**Primary Dependencies**: drift 2.x, flutter_riverpod 3.x, riverpod_annotation, go_router, share_plus (신규)
**Storage**: SQLite via drift — `CreditAccount` 테이블에 `phone`, `note` nullable 컬럼 추가, 마이그레이션 버전 증가
**Testing**: flutter_test + mockito (unit/widget), integration_test + NativeDatabase.memory() (통합)
**Target Platform**: Android 8.0+ / iOS 14+ 태블릿 (10인치 이상), 가로 레이아웃 최적화
**Project Type**: Flutter 모바일 앱 (로컬 전용, 백엔드 없음)
**Performance Goals**: SeatGridPage 초기 로드 < 300ms (N+1 제거 후), 내보내기 < 3s, 화면 전환 < 300ms
**Constraints**: 기존 CreditAccount 데이터 마이그레이션 필수, 오프라인 우선, domain 레이어 Flutter 의존 금지
**Scale/Scope**: drift 마이그레이션 버전 +1, 신규 UseCase 2개, 신규 DAO 메서드 4개, 신규 패키지 1개(share_plus)

## Constitution Check

*GATE: Phase 0 시작 전 확인. Phase 1 설계 완료 후 재확인.*

| Principle | Check | Status |
|-----------|-------|--------|
| **I. Code Quality — 단일 책임** | UseCase 1개당 1개 책임(Add/RemoveOrderItem 분리), 에러 매핑 유틸은 presentation 레이어 한정 | ✅ PASS |
| **I. Code Quality — 하드코딩 금지** | 폰트 크기(18sp, 20sp)를 `AppTypography` 토큰으로 정의, raw pixel 값 컴포넌트에 금지 | ✅ PASS |
| **I. Code Quality — 의존성 최소화** | share_plus만 신규 추가, 안정 버전 고정 | ✅ PASS |
| **II. Test Standards — TDD** | AddOrderItemUseCase, RemoveOrderItemUseCase 테스트 먼저 작성(RED) 후 구현 | ✅ PASS |
| **II. Test Standards — 통합 테스트 실 DB** | drift 마이그레이션 검증은 NativeDatabase.memory() 인메모리 DB 사용 | ✅ PASS |
| **II. Test Standards — 커버리지 80%** | 신규 UseCase, 신규 DAO 메서드, 에러 매핑 유틸 모두 단위 테스트 작성 | ✅ PASS |
| **III. UX — 디자인 토큰** | 18sp/20sp 폰트 크기를 `AppTypography`에 추가, 컴포넌트에 raw 값 사용 금지 | ✅ PASS |
| **III. UX — 파괴적 액션 확인** | 주문 취소 다이얼로그 경고 문구 강화, 삭제 버튼 명시화 | ✅ PASS |
| **III. UX — 에러 메시지** | exception 직접 노출 제거, 한국어 안내 + 해결 방법 포함 | ✅ PASS |
| **IV. Performance** | SeatGridPage N+1 → batch 쿼리 1회로 교체, 300ms 이내 렌더링 목표 | ✅ PASS |
| **Quality Gates** | `dart analyze` zero warnings, `flutter test --coverage` CI, 마이그레이션 테스트 포함 | ✅ PASS |

*Phase 1 이후 재확인: CreditAccount 마이그레이션 스크립트 검토, BatchQuery DAO 인터페이스 추상화 충분성 검토*

## Project Structure

### Documentation (this feature)

```text
specs/002-ux-improvements/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (스키마 변경 사항)
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (변경된 Repository 인터페이스)
│   ├── order-repository.md    # AddOrderItem, RemoveOrderItem
│   ├── seat-repository.md     # watchAllWithActiveOrders
│   └── credit-account-repository.md  # phone/note CRUD
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (영향받는 파일 목록)

```text
lib/
├── domain/
│   ├── entities/
│   │   └── credit_account.dart         # phone?, note? 필드 추가
│   └── usecases/
│       ├── order/
│       │   ├── add_order_item_use_case.dart     # 신규
│       │   └── remove_order_item_use_case.dart  # 신규
│       └── credit/
│           └── export_data_use_case.dart        # 신규
│
├── data/local/
│   ├── database/
│   │   └── app_database.dart           # 마이그레이션 버전 +1, phone/note 컬럼 추가
│   └── daos/
│       ├── order_dao.dart              # addItem(), removeItem() 메서드 추가
│       ├── seat_dao.dart               # watchAllWithActiveOrders() 배치 쿼리 추가
│       └── credit_account_dao.dart     # phone/note CRUD 업데이트
│
├── presentation/
│   ├── theme/
│   │   └── app_typography.dart         # bodyLarge 18sp, priceStyle 20sp bold 토큰 추가
│   ├── utils/
│   │   └── error_message_mapper.dart   # 신규 — exception → 한국어 메시지 매핑
│   └── pages/
│       ├── order/
│       │   ├── order_detail_page.dart  # bug fix: items DB 연결, PENDING 항목 편집 UI
│       │   ├── create_order_page.dart  # 품절 메뉴 시각 차단
│       │   └── seat_grid_page.dart     # N+1 → batch provider 교체
│       ├── credit/
│       │   ├── credit_account_detail_page.dart  # 연락처·메모 표시, 거래→주문 딥링크
│       │   └── credit_account_form_page.dart    # phone/note 입력 필드 추가
│       └── settings/
│           ├── menu_settings_page.dart          # 명시적 삭제 버튼
│           ├── seat_settings_page.dart          # 명시적 삭제 버튼
│           └── settings_page.dart               # 데이터 내보내기 버튼 추가

test/
├── domain/usecases/order/
│   ├── add_order_item_use_case_test.dart   # 신규 TDD
│   └── remove_order_item_use_case_test.dart # 신규 TDD
├── domain/usecases/credit/
│   └── export_data_use_case_test.dart      # 신규
├── data/
│   ├── daos/order_dao_test.dart             # addItem/removeItem 추가
│   ├── daos/seat_dao_test.dart              # watchAllWithActiveOrders 추가
│   └── migrations/
│       └── migration_v2_test.dart           # phone/note 마이그레이션 검증 (신규)
└── presentation/
    ├── pages/order/order_detail_page_test.dart  # bug fix 검증 위젯 테스트 (신규)
    └── utils/error_message_mapper_test.dart     # 한국어 메시지 매핑 테스트 (신규)
```

**Structure Decision**: Flutter Clean Architecture 단일 앱 구조 유지. 신규 파일 추가 시 기존 계층(domain/data/presentation) 규칙 준수. `share_plus` 패키지 호출은 presentation 레이어의 UseCase 어댑터 형태로 감싸 domain 레이어 순수성 유지.

## Implementation Steps

### Phase 0 — Critical Bug Fix (P0)

**Step 1**: `order_detail_page.dart` 버그 수정

- 파일: `lib/presentation/pages/order/order_detail_page.dart:57`
- 변경: `_OrderItemList(items: const [], ...)` → Riverpod provider를 통해 해당 order의 items를 조회하여 전달
- `OrderDao.findById()` 또는 별도 `watchOrderItems(orderId)` stream을 provider로 노출
- 선행 조건: 기존 `OrderDao`에 `watchItems(orderId)` stream 메서드 존재 여부 확인 후 없으면 추가

**Step 2**: `order_detail_page_test.dart` 위젯 테스트 신규 작성

- 항목 포함 주문을 seed로 생성 후 `OrderDetailPage` 렌더링
- `find.text('김치찌개')` 등 실제 항목이 표시되는지 검증
- 빈 항목 주문의 경우 "주문 항목 없음" 텍스트 표시 검증

---

### Phase 1 — 60대 접근성 개선 (P1)

**Step 3**: `app_typography.dart` 폰트 토큰 추가

- `static const TextStyle bodyLarge = TextStyle(fontSize: 18, ...)` (이미 있으면 fontSize 확인 후 18sp로 업데이트)
- `static const TextStyle priceStyle = TextStyle(fontSize: 20, fontWeight: FontWeight.bold, ...)`
- 영향받는 위젯: `OrderItemTile`, `MenuItemCard`, `PaymentAmountDisplay` 등 가격 표시 위젯 일괄 교체

**Step 4**: 메뉴·좌석 설정 화면 삭제 버튼 명시화

- `menu_settings_page.dart`: 각 ListTile에 trailing `IconButton(icon: Icon(Icons.delete_outline), ...)` 추가
- `seat_settings_page.dart`: 동일하게 trailing 삭제 버튼 추가
- 기존 롱프레스 핸들러 제거 (또는 유지하되 명시적 버튼 병행 제공)
- 확인 다이얼로그는 기존 패턴 유지

**Step 5**: 주문 취소 확인 다이얼로그 경고 문구 강화

- 파일: `lib/presentation/pages/order/order_detail_page.dart` (취소 다이얼로그 부분)
- 기존 "주문을 취소하시겠습니까?" → "주문을 취소하면 되돌릴 수 없습니다. 계속하시겠습니까?"

**Step 6**: `error_message_mapper.dart` 신규 작성

- `lib/presentation/utils/error_message_mapper.dart`
- 도메인 exception 타입(BusinessDayNotFoundException, OrderNotEditableException 등)별 한국어 메시지 반환
- 미등록 exception은 기본 메시지("오류가 발생했습니다. 앱을 다시 시작해 주세요.") 반환
- 기존 에러 표시 위젯에서 이 유틸을 통해 메시지 변환

---

### Phase 2 — PENDING 주문 항목 수정 (P2)

**Step 7**: `AddOrderItemUseCase` TDD 구현

- 먼저 `test/domain/usecases/order/add_order_item_use_case_test.dart` 작성 (RED)
  - PENDING 주문에 항목 추가 성공 케이스
  - DELIVERED 주문에 추가 시도 → `OrderNotEditableException`
  - 품절 메뉴 추가 시도 → `MenuNotAvailableException`
- `lib/domain/usecases/order/add_order_item_use_case.dart` 구현 (GREEN)

**Step 8**: `RemoveOrderItemUseCase` TDD 구현

- `test/domain/usecases/order/remove_order_item_use_case_test.dart` 작성 (RED)
  - PENDING 주문에서 항목 삭제 성공
  - 마지막 항목 삭제 시도 → `MinimumOrderItemException`
  - DELIVERED 주문에서 삭제 시도 → `OrderNotEditableException`
- `lib/domain/usecases/order/remove_order_item_use_case.dart` 구현 (GREEN)

**Step 9**: `OrderDao` addItem / removeItem 메서드 추가

- `lib/data/local/daos/order_dao.dart`에 `addItem(orderId, menuItemId, quantity)`, `removeItem(orderId, orderItemId)` 추가
- `test/data/daos/order_dao_test.dart`에 해당 테스트 추가
- 총액 재계산 트리거: addItem/removeItem 후 order.totalAmount 업데이트

**Step 10**: `order_detail_page.dart` PENDING 항목 편집 UI 추가

- 상태가 PENDING일 때 항목 목록 하단에 "+ 메뉴 추가" 버튼 표시
- 각 항목에 삭제 버튼 표시 (PENDING 상태에서만 활성화)
- DELIVERED/PAID 상태에서는 해당 버튼 숨김

**Step 11**: `create_order_page.dart` 품절 메뉴 시각 차단

- `isAvailable == false`인 메뉴 카드에 opacity 0.4 적용
- 탭 시 AddItem 대신 SnackBar "현재 판매하지 않는 메뉴입니다." 표시

---

### Phase 3 — 외상 계좌 데이터 강화 (P3)

**Step 12**: `CreditAccount` 엔티티 확장

- `lib/domain/entities/credit_account.dart`: `phone`, `note` nullable String 필드 추가
- `lib/data/local/database/app_database.dart`: `CreditAccountsTable`에 `phone`, `note` TextColumn 추가

**Step 13**: drift 마이그레이션 스크립트 작성

- `app_database.dart` 스키마 버전 +1 (예: 2 → 3)
- `MigrationStrategy`의 `onUpgrade`에 `addColumn` 등록:
  ```dart
  if (from < 3) {
    await m.addColumn(creditAccounts, creditAccounts.phone);
    await m.addColumn(creditAccounts, creditAccounts.note);
  }
  ```
- `test/data/migrations/migration_v2_test.dart` 신규 작성:
  - 이전 버전 DB에서 업그레이드 후 기존 계좌 데이터 보존 검증

**Step 14**: `credit_account_form_page.dart` 연락처·메모 필드 추가

- 이름 필드 아래에 연락처(선택), 메모(선택) TextField 추가
- 저장 시 phone/note 포함하여 `CreditAccountDao.create()` / `update()` 호출

**Step 15**: `credit_account_detail_page.dart` 딥링크 및 연락처 표시

- 계좌 상세 상단에 phone/note 필드 표시 (값 없으면 숨김)
- 거래 이력 목록에서 "외상 발생" 항목 탭 시 `context.push('/order-detail/${transaction.orderId}')` 네비게이션
- (연결된 주문이 취소된 경우 "해당 주문을 찾을 수 없습니다." 스낵바)

---

### Phase 4 — 성능 및 백업 (P4)

**Step 16**: `SeatDao.watchAllWithActiveOrders()` 배치 쿼리 추가

- `lib/data/local/daos/seat_dao.dart`에 seats + orders JOIN 쿼리 추가
  ```dart
  // SELECT s.*, o.* FROM seats s LEFT JOIN orders o ON o.seat_id = s.id
  // WHERE o.status IN ('pending','delivered') OR o.id IS NULL
  ```
- `SeatWithActiveOrder` value object (Seat + nullable Order) 반환
- `test/data/daos/seat_dao_test.dart`에 배치 쿼리 테스트 추가

**Step 17**: `seat_grid_page.dart` N+1 → batch provider 교체

- 기존: `ref.watch(activeOrderBySeatProvider(seat.id))` for each seat (N+1)
- 변경: `ref.watch(seatsWithActiveOrdersProvider)` → `Map<String, Order?>` 반환
- 위젯 트리에서 각 SeatCard는 map에서 자신의 order를 O(1) 조회
- 기존 `activeOrderBySeatProvider` 는 유지 (다른 화면에서 사용 중일 수 있음)

**Step 18**: `ExportDataUseCase` + 내보내기 UI 구현

- `lib/domain/usecases/export_data_use_case.dart`: 전체 영업일·주문·외상 데이터를 JSON으로 직렬화
- `lib/presentation/pages/settings/settings_page.dart`에 "데이터 내보내기" 버튼 추가
- `share_plus` 패키지로 임시 파일 생성 후 Share sheet 호출
- 파일명 형식: `pos_backup_YYYYMMDD.json`

---

## Acceptance Criteria

모든 기준은 자동화 테스트로 검증 가능해야 한다.

| ID | 기준 | 검증 방법 |
|----|------|-----------|
| AC-B01 | 주문 상세 화면에서 DB에 저장된 항목이 표시된다 | 위젯 테스트: `find.text('김치찌개')` |
| AC-A01 | `AppTypography.priceStyle.fontSize == 20.0` | 단위 테스트 |
| AC-A02 | 메뉴 설정 화면 각 항목에 삭제 아이콘 버튼 표시 | 위젯 테스트: `find.byIcon(Icons.delete_outline)` |
| AC-A03 | 취소 다이얼로그에 "되돌릴 수 없습니다" 포함 | 위젯 테스트: `find.text(contains('되돌릴'))` |
| AC-A04 | `BusinessDayNotFoundException` → 한국어 메시지 반환 | 단위 테스트: `errorMessageMapper.map(e)` |
| AC-P01 | PENDING 주문에 항목 추가 → 총액 재계산 | DAO 통합 테스트 |
| AC-P02 | DELIVERED 주문에서 항목 추가 시도 → 예외 발생 | UseCase 단위 테스트 |
| AC-P03 | 마지막 항목 삭제 시도 → `MinimumOrderItemException` | UseCase 단위 테스트 |
| AC-P04 | 품절 메뉴 탭 → SnackBar "판매하지 않는 메뉴" 표시 | 위젯 테스트 |
| AC-C01 | CreditAccount phone/note 저장·조회 | DAO 통합 테스트 |
| AC-C02 | 기존 계좌 마이그레이션 후 데이터 보존 | 마이그레이션 테스트 |
| AC-C03 | 거래 이력 탭 → 주문 상세 라우팅 | 위젯 테스트: `find.byType(OrderDetailPage)` |
| AC-X01 | SeatGridPage 로드 시 DB 쿼리 1회 | DAO 메서드 호출 횟수 검증 |
| AC-X02 | 내보내기 실행 → Share sheet 표시 | 통합 테스트 (share_plus mock) |

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| drift 마이그레이션 실수로 기존 데이터 손실 | Low | High | `migration_v2_test.dart`에서 업그레이드 전후 데이터 동일성 검증 필수. 마이그레이션 전 `addColumn`만 사용(컬럼 삭제·변경 없음) |
| N+1 → batch 전환 후 실시간 watch stream 끊김 | Medium | Medium | `watchAllWithActiveOrders()`를 drift `watch` 기반으로 구현하여 stream 유지. 전환 후 smoke test |
| share_plus 패키지 플랫폼 별 동작 차이 | Medium | Low | Android/iOS 각각 `flutter test integration_test/`로 검증. 실패 시 "내보내기 완료, 파일 위치: ..." 대체 UI |
| AddOrderItemUseCase 비즈니스 규칙 누락 | Low | Medium | TDD로 edge case(품절, DELIVERED, 마지막 항목 삭제 등) 먼저 명세 |
| 에러 메시지 매핑 누락 exception | Medium | Low | 기본 fallback 메시지 필수, `dart analyze`로 exhaustive switch 강제 |

## Verification Steps

1. `dart analyze` — zero warnings (마이그레이션 코드 포함)
2. `flutter test` — 기존 테스트 100% 통과 + 신규 테스트 통과
3. `flutter test --coverage` — domain + data 레이어 80% 이상 유지
4. 수동: 에뮬레이터에서 주문 생성 후 상세 화면에서 항목 표시 확인 (P0 bug fix)
5. 수동: 메뉴 설정 화면에서 명시적 삭제 버튼으로 메뉴 삭제 확인
6. 수동: PENDING 주문 상세에서 항목 추가·삭제 후 총액 재계산 확인
7. 수동: 외상 계좌 등록 시 연락처 저장 및 거래 이력 딥링크 확인
8. 수동: 설정 화면 "데이터 내보내기" 실행 후 Share sheet 표시 확인

## CLAUDE.md 업데이트 지침

구현 시작 전 `CLAUDE.md`의 plan 참조 경로를 다음으로 업데이트한다:

```
specs/002-ux-improvements/plan.md
```

각 Phase 구현 시 해당 Phase의 Step을 먼저 테스트(TDD), 이후 구현, `dart analyze` 확인 순서로 진행한다.
