# Restaurant POS

음식점 점주를 위한 Flutter 기반 태블릿 POS 앱.

주문 접수·전달·결제(즉시/외상)의 전체 흐름, 영업 시작/마감 기반 일일 매출 정산, 외상 장부 관리, 메뉴·좌석 설정을 제공한다.

---

## 주요 기능

- **주문 관리**: 좌석 선택 → 메뉴 선택 → 주문 생성 → 전달 완료 상태 추적
- **결제 처리**: 즉시 결제(현금·카드) 및 외상 결제 선택
- **외상 장부**: 고객별 외상 계좌 등록, 잔액 조회, 납부 처리
- **영업 일과 관리**: 영업 시작/마감 및 일일 매출 보고서 생성·조회
- **설정**: 메뉴 항목(가격·판매 여부) 및 좌석 관리

---

## 기술 스택

| 영역 | 기술 |
|------|------|
| UI 프레임워크 | Flutter 3.22+ |
| 언어 | Dart 3.x |
| 로컬 DB | drift 2.x (SQLite) |
| 상태 관리 / DI | flutter_riverpod 3.x + riverpod_annotation |
| 라우팅 | go_router |
| 테스트 | flutter_test, mockito, integration_test |

> 백엔드 없음 — 모든 데이터는 기기 로컬 SQLite에 저장된다.

---

## 플랫폼

- **Android** 8.0 (API 26) 이상
- **iOS** 14 이상
- 10인치 이상 태블릿, 가로(landscape) 레이아웃 최적화

---

## 설치 및 실행

### 요구 사항

- Flutter SDK 3.22 이상
- Dart SDK 3.3 이상

### 설치

```bash
flutter pub get
```

### 코드 생성 (drift 스키마 / Riverpod provider 변경 시 필수)

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 앱 실행

```bash
flutter run
```

---

## 테스트

```bash
# 단위 + 위젯 테스트
flutter test

# 커버리지 측정 (domain + data 레이어 80% 이상 필수)
flutter test --coverage

# 통합 테스트 (에뮬레이터 또는 실기기 필요)
flutter test integration_test/
```

---

## 린트 및 포맷

```bash
# 정적 분석 (zero warnings 필수)
dart analyze

# 코드 포맷
dart format .
```

---

## 아키텍처

Clean Architecture 3계층. **domain 레이어는 Flutter·drift에 의존하지 않는다.**

```
lib/
├── domain/        # 순수 Dart — entities, repositories(abstract), usecases
├── data/
│   ├── local/     # drift SQLite 구현체
│   └── remote/    # 백엔드 전환 시 HTTP 구현체 위치 (현재 stub)
├── presentation/  # Flutter UI — pages, widgets, providers (Riverpod)
└── core/          # DI, router, utils
```

백엔드 전환 시 `lib/core/di/providers.dart`의 주입 대상만 `LocalXxxRepository` → `RemoteXxxRepository`로 교체하면 된다.
