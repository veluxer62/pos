<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
at specs/001-restaurant-pos/plan.md
<!-- SPECKIT END -->

---

## 프로젝트 개요

음식점 점주를 위한 Flutter 기반 태블릿 POS 앱. 주문 접수·전달·결제(즉시/외상)의 전체 흐름, 영업 시작/마감 기반 일일 매출 정산, 외상 장부 관리, 메뉴·좌석 설정을 제공한다.

- **플랫폼**: Android 8.0+ / iOS 14+ 태블릿 (10인치 이상), 가로 레이아웃 최적화
- **저장소**: drift 2.x (SQLite) — 로컬 전용, 백엔드 없음
- **통화**: KRW 원 단위 정수
- **스펙**: `specs/001-restaurant-pos/`

---

## 아키텍처

Clean Architecture 3계층. **domain 레이어는 Flutter·drift에 의존하지 않는다.**

```
lib/
├── domain/                  # 순수 Dart — entities, repositories(abstract), usecases, value_objects, exceptions
├── data/
│   ├── local/               # drift SQLite 구현체 (database, daos, repositories)
│   └── remote/              # 백엔드 전환 시 HTTP 구현체 위치 (현재 stub)
├── presentation/            # Flutter UI — theme, widgets, pages, providers (Riverpod)
└── core/                    # DI (Riverpod), router (go_router), utils

test/
├── domain/                  # UseCase 단위 테스트 (mockito)
├── data/                    # DAO·Repository 통합 테스트 (in-memory drift)
├── presentation/            # Widget 테스트
└── integration_test/        # 전체 시나리오
```

**백엔드 전환 시**: `lib/core/di/providers.dart`의 주입 대상만 `LocalXxxRepository` → `RemoteXxxRepository`로 교체. domain·presentation 변경 없음.

---

## 코드 스타일

- **Dart 강타입**: `analysis_options.yaml` strict lint 적용, `dart analyze` zero warnings 필수
- **Repository 패턴**: `abstract interface class IXxxRepository` → `LocalXxxRepository` 구현체
- **상태 관리**: Riverpod 2.x (`@riverpod` 코드 생성), `AsyncNotifier` 비동기 상태
- **상태 머신**: `sealed class OrderStatus` + exhaustive switch (컴파일 타임 안전성)
- **금액**: `IntColumn` KRW 원 단위 정수, UI 표시 시 `CurrencyFormatter` 사용
- **날짜/시간**: drift `DateTimeColumn` (내부 INTEGER milliseconds)
- **UUID**: `UuidTextConverter`로 TEXT 저장
- **Enum**: `TextColumn + textEnum<>()` TEXT 저장 (가독성·마이그레이션 안전)
- **디자인 토큰**: `AppColors`, `AppSpacing`, `AppTypography` — 컴포넌트에 raw hex/pixel 값 금지
- **접근성**: 버튼 최소 터치 영역 48dp, `Semantics` 위젯 적용
- **주석**: 비자명한 WHY만 작성, 코드 설명 주석 금지

---

## 명령어

```bash
# 의존성 설치
flutter pub get

# 코드 생성 (drift 스키마 변경 또는 Riverpod provider 추가 시 필수)
dart run build_runner build --delete-conflicting-outputs

# 앱 실행
flutter run

# 테스트 (단위 + 위젯)
flutter test

# 커버리지 (domain + data 레이어 80% 이상 필수)
flutter test --coverage

# 통합 테스트 (에뮬레이터/실기기 필요)
flutter test integration_test/

# 린트 (zero warnings 필수)
dart analyze

# 포맷
dart format .
```

---

## 중요사항

### TDD 필수 (Constitution II)

모든 UseCase·DAO 구현 전 테스트를 먼저 작성하고 실패(RED)를 확인 후 구현한다.

- UseCase 테스트: `test/domain/usecases/` — mockito로 repository mock
- DAO·Repository 테스트: `test/data/` — `NativeDatabase.memory()` in-memory drift (mock DB 금지)

### drift 코드 생성 의존성

테이블 정의 또는 `@riverpod` provider 변경 시 반드시 build_runner를 재실행한다.

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 영업일(BusinessDay) 체크

주문 생성·상태 변경은 OPEN 영업일이 없으면 `BusinessDayNotFoundException` 발생. UseCase 레벨에서 `IBusinessDayRepository.getOpen()` 선행 확인 필수.

### 원자적 트랜잭션

- 영업 마감 + DailySalesReport 생성: drift `transaction()` 블록 내 처리
- 외상 발생(charge) + Order 상태 변경: 동일 트랜잭션 처리
- 외상 납부(pay) + CreditAccount balance 업데이트: 동일 트랜잭션 처리

### 삭제 제약

| 엔티티 | 삭제 조건 |
|--------|----------|
| MenuItem | 활성 주문(PENDING/DELIVERED) 미참조 — 참조 중이면 `isAvailable=false` soft delete |
| Seat | 활성 주문 미연결 |
| CreditAccount | `balance == 0`인 경우만 |

### V1 범위 외

- SC-010·FR-035 서버 동기화 → 백엔드 연동 단계 적용
- 메뉴 이미지/사진
- 보고서 PDF 내보내기·인쇄
- 앱 전용 PIN (기기 잠금 화면에 위임)
- 시각적 좌석 평면도 레이아웃
