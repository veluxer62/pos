# Implementation Plan: Restaurant POS App

**Branch**: `001-restaurant-pos` | **Date**: 2026-04-19 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-restaurant-pos/spec.md`

## Summary

음식점 점주를 위한 Flutter 기반 태블릿 POS 앱. 주문 접수·전달·결제(즉시/외상)의 전체 흐름과 영업 시작/마감 기반 일일 매출 정산, 외상 장부 관리, 메뉴·좌석 설정을 제공한다. 초기에는 로컬 SQLite(drift)로 모든 데이터를 저장하며, Repository 인터페이스 추상화로 추후 백엔드 전환이 용이하도록 설계한다.

## Technical Context

**Language/Version**: Dart 3.x
**Primary Dependencies**: Flutter 3.x (UI), drift (SQLite ORM), flutter_riverpod (상태관리/DI), go_router (라우팅)
**Storage**: SQLite via drift — 단일 기기 로컬 저장소. 백엔드 전환 시 `RemoteXxxRepository`로 교체.
**Testing**: flutter_test + mockito (unit/widget), integration_test (통합), patrol 또는 flutter_driver (E2E)
**Target Platform**: Android 8.0+ / iOS 14+ 태블릿 (10인치 이상), 가로 레이아웃 최적화
**Project Type**: Flutter 단일 앱 (백엔드 없음, 로컬 우선)
**Performance Goals**: 주문 생성 < 2s, 화면 전환 < 300ms, 결제 화면 로드 < 500ms, 보고서 생성 < 5s
**Constraints**: 오프라인 우선(항상 로컬 동작), Repository 추상화 필수, 단일 매장·KRW
**Scale/Scope**: 최대 100석, 하루 ~500건 주문, 단일 기기 운영

## Constitution Check

*GATE: Phase 0 시작 전 확인. Phase 1 설계 완료 후 재확인.*

| Principle | Check | Status |
|-----------|-------|--------|
| **I. Code Quality** | Dart 강타입 + `analysis_options.yaml` strict lint, 단일 책임 레이어(domain/data/presentation), 상수는 `AppConstants` 파일로 분리 | ✅ PASS |
| **I. Code Quality** | drift + flutter_riverpod pinned stable versions, 최소 의존성 | ✅ PASS |
| **II. Test Standards** | TDD 의무(Red→Green→Refactor), 비즈니스 로직(use case·domain) 80% coverage 목표, Repository mock으로 단위 테스트 | ✅ PASS |
| **II. Test Standards** | 통합 테스트는 실제 in-memory drift DB 사용 (mock store 금지) | ✅ PASS |
| **III. UX Consistency** | `AppTheme`에 디자인 토큰(색상·간격·타이포) 정의, 컴포넌트에 raw hex 값 금지 | ✅ PASS |
| **III. UX Consistency** | 취소·환불·마감 등 파괴적 액션은 확인 다이얼로그 필수, 접근성(Semantics 위젯) 적용 | ✅ PASS |
| **IV. Performance** | SQLite 인덱스로 보고서 쿼리 최적화, 화면 전환 300ms 이내, drift 스트림으로 실시간 UI 갱신 | ✅ PASS |
| **Quality Gates** | `dart analyze` zero warnings, `dart format`, `flutter test --coverage` CI 필수 | ✅ PASS |

*Phase 1 이후 재확인: Repository 인터페이스 설계 완료 후 추상화 레이어 충분성 검토*

## Project Structure

### Documentation (this feature)

```text
specs/001-restaurant-pos/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (drift schema)
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (Repository 인터페이스)
│   ├── order-repository.md
│   ├── business-day-repository.md
│   ├── credit-account-repository.md
│   ├── menu-item-repository.md
│   └── seat-repository.md
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
lib/
├── domain/                        # 순수 Dart — UI·저장소 의존 없음
│   ├── entities/                  # Order, Seat, MenuItem, BusinessDay, CreditAccount 등
│   ├── repositories/              # abstract 인터페이스 (IOrderRepository 등)
│   ├── usecases/                  # 비즈니스 로직 단위 (CreateOrderUseCase 등)
│   └── value_objects/             # OrderStatus enum, PaymentType enum 등
│
├── data/
│   ├── local/                     # 현재: drift(SQLite) 구현체
│   │   ├── database/              # AppDatabase, drift 스키마 테이블 정의
│   │   ├── daos/                  # OrderDao, SeatDao 등 drift DAO
│   │   └── repositories/         # LocalOrderRepository implements IOrderRepository
│   └── remote/                    # 미래: HTTP 구현체 스텁
│       └── repositories/         # RemoteOrderRepository implements IOrderRepository
│
├── presentation/
│   ├── theme/                     # AppTheme, AppColors, AppSpacing, AppTypography
│   ├── widgets/                   # 공유 UI 컴포넌트 (AppButton, ConfirmDialog 등)
│   ├── pages/
│   │   ├── order/                 # US1: 주문 접수 및 전달 관리
│   │   ├── payment/               # US2: 결제 처리 (즉시/외상)
│   │   ├── credit/                # US3: 외상 장부 및 납부
│   │   ├── business_day/          # US4: 영업 시작/마감 및 보고서
│   │   └── settings/              # US5: 메뉴·좌석 설정
│   └── providers/                 # Riverpod provider 정의
│
└── core/
    ├── di/                        # ProviderScope 설정, 구현체 주입
    ├── router/                    # go_router 라우트 정의
    └── utils/                     # 금액 포맷터, 날짜 유틸 등

test/
├── domain/                        # Use case 단위 테스트 (mock repository 사용)
├── data/                          # DAO·Repository 통합 테스트 (in-memory drift)
├── presentation/                  # Widget 테스트
└── integration/                   # 전체 앱 시나리오 (integration_test)
```

**Structure Decision**: Flutter 단일 앱. Clean Architecture 3계층(domain/data/presentation)으로 분리하여 `domain` 레이어는 저장소·UI에 의존하지 않는다. `data/local`이 현재 구현이고, `data/remote`는 백엔드 전환 시 추가하는 stub 위치다. `core/di`에서 `IOrderRepository`에 `LocalOrderRepository`를 주입하며, 백엔드 전환 시 이 한 곳만 수정하면 된다.

## Complexity Tracking

> Constitution Check 위반 없음 — 해당 없음
