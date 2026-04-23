---
name: "code-review"
description: >
  Flutter/Dart 코드 리뷰를 수행하는 스킬. 이전 대화 컨텍스트 없이 코드와 프로젝트 요구사항만을 기반으로
  독립적인 리뷰를 수행한다. 사용자가 "코드 리뷰", "리뷰해줘", "review", "/code-review",
  변경된 코드에 대한 품질 검사, 아키텍처 준수 확인, PR 리뷰를 요청할 때 이 스킬을 사용한다.
  구현이 완료된 태스크, 특정 파일, 또는 git 변경사항 전체에 대해 실행할 수 있다.
argument-hint: "[파일경로 또는 태스크ID] — 생략 시 git diff(HEAD) 기준으로 변경된 파일 전체 리뷰"
user-invocable: true
---

## User Input

```text
$ARGUMENTS
```

## 개요

이 스킬은 **컨텍스트가 없는 독립 에이전트**로 코드 리뷰를 수행한다. 에이전트는 이전 대화 내용을 알지 못하며,
프로젝트 파일에서 직접 요구사항을 읽어 순수하게 코드 품질과 구조 요구사항 충족 여부를 판단한다.

## 실행 단계

### 1. 리뷰 대상 파일 결정

인자가 있으면:
- 특정 파일 경로 → 해당 파일만 리뷰
- 태스크 ID (예: T005) → tasks.md에서 해당 태스크의 파일 경로 추출

인자가 없으면:
```bash
git diff --name-only HEAD~1 HEAD 2>/dev/null || git diff --name-only --cached
```
변경된 Dart 파일(`.dart`) 전체를 리뷰 대상으로 설정.

### 2. 프로젝트 요구사항 로드 (컨텍스트 자동 구성)

다음 파일들을 순서대로 읽어 리뷰 기준을 구성한다. 파일이 없으면 건너뛴다.

1. `CLAUDE.md` — 아키텍처, 코드 스타일, 중요사항
2. `specs/001-restaurant-pos/plan.md` — 기술 스택, 프로젝트 구조
3. `.specify/memory/constitution.md` — 핵심 원칙 (Code Quality, Test Standards, UX, Performance)
4. `analysis_options.yaml` — lint 규칙

### 3. 서브에이전트로 독립 리뷰 실행

아래 프롬프트로 **Agent 도구**를 사용해 컨텍스트 없는 서브에이전트를 생성한다.
서브에이전트에게는 이 프롬프트만 제공되며, 이전 대화 내용은 전달하지 않는다.

---

**서브에이전트 프롬프트 템플릿**:

```
당신은 Flutter/Dart 코드 리뷰어입니다. 이전 대화 컨텍스트가 없으며,
아래 제공된 요구사항과 코드만을 기반으로 독립적으로 리뷰를 수행하세요.

## 프로젝트 요구사항

[CLAUDE.md 내용 삽입]

## 핵심 원칙 (Constitution)

[constitution.md 핵심 섹션 삽입]

## 리뷰 대상 파일 목록

[변경 파일 목록]

## 리뷰 기준

아래 항목을 순서대로 검사하세요.

### A. dart analyze 실행
```bash
export PATH="$PATH:$HOME/flutter/bin"
dart analyze [파일경로들]
```
출력된 error/warning/info를 모두 수집한다.

### B. 아키텍처 준수 검사
다음 규칙을 Dart import 문과 코드 구조로 확인한다:
- `lib/domain/` 파일: `package:flutter`, `drift`, `riverpod` import 없어야 함 (순수 Dart)
- `lib/data/local/` 파일: `drift`, `sqlite3` 사용 가능. UI import 없어야 함
- `lib/presentation/` 파일: domain entity/usecase 사용 가능. drift 직접 참조 불가
- `lib/core/di/` 파일: repository 구현체 바인딩 위치. 유일한 교체 포인트
- cross-layer dependency (예: domain → data, presentation → data.local) 금지

### C. Repository 패턴 검사
- `I[Name]Repository`: `abstract interface class`로 정의되어야 함
- `Local[Name]Repository`: `implements I[Name]Repository`를 명시해야 함
- DAO는 `lib/data/local/daos/`에만 위치해야 함

### D. 코드 품질 검사 (analysis_options.yaml 기준)
- `prefer_final_fields`, `prefer_final_locals`: 가변 필드/변수 불필요 여부
- `require_trailing_commas`: 멀티라인 파라미터/인자 목록 trailing comma 여부
- `avoid_dynamic_calls`: dynamic 타입 사용 여부
- `always_declare_return_types`: 반환 타입 명시 여부
- raw hex/pixel 값 (`0xFF...`, `Color(0x...)`, 숫자 px 직접 사용): `AppColors`, `AppSpacing` 사용 필수
- `avoid_print`: print() 직접 사용 금지

### E. drift 패턴 검사
- Enum 컬럼: `textEnum<T>()` 사용 여부 (int 기반 enum 금지)
- FK 참조: `.references(Table, #id)` 방식 사용 여부
- 원자적 처리 필요 연산 (외상+주문, 마감+보고서): `database.transaction()` 블록 사용 여부
- UUID: `UuidTextConverter` 적용 여부

### F. Riverpod 패턴 검사
- `@riverpod` 코드 생성 어노테이션 사용 여부 (`Provider` 직접 생성 지양)
- 비동기 상태: `AsyncNotifier` 또는 `AsyncNotifierProvider` 사용 여부
- `.g.dart` 파일 참조: `part '...'` 선언 존재 여부

### G. TDD 준수 확인
- 새로운 UseCase 파일 (`lib/domain/usecases/`) 존재 시: 대응하는 테스트 파일(`test/domain/usecases/`) 존재 여부
- 새로운 DAO 파일 (`lib/data/local/daos/`) 존재 시: 대응하는 테스트 파일(`test/data/daos/`) 존재 여부
- 테스트에서 drift in-memory DB 사용 여부 (`NativeDatabase.memory()`)

### H. 주석 및 문서 품질
- 자명한 코드 설명 주석 금지 (WHY만 허용)
- 불필요한 TODO/FIXME 방치 여부

## 리뷰 리포트 형식

아래 형식으로 리포트를 출력한다. 각 항목에 파일 경로와 라인 번호를 반드시 포함한다.

---

# Code Review Report

**리뷰 일시**: [현재 시각]  
**리뷰 대상**: [파일 목록]  
**검사 항목**: dart analyze, 아키텍처, 코드 품질, drift/Riverpod 패턴, TDD

---

## 요약

| 심각도 | 건수 |
|--------|------|
| Critical (반드시 수정) | N |
| Warning (수정 권장) | N |
| Info (참고) | N |

**종합 판정**: `PASS` / `NEEDS WORK` / `FAIL`

- PASS: Critical 0건, Warning 2건 이하
- NEEDS WORK: Critical 0건, Warning 3건 이상
- FAIL: Critical 1건 이상

---

## Critical (반드시 수정)

### [파일경로:라인번호] 제목
**규칙**: [위반한 규칙]  
**문제**: [구체적 문제 설명]  
**수정 방법**: [코드 예시 또는 설명]

---

## Warning (수정 권장)

### [파일경로:라인번호] 제목
**규칙**: [위반한 규칙]  
**문제**: [구체적 문제 설명]

---

## Info (참고)

- `[파일경로:라인번호]`: [개선 제안]

---

## 아키텍처 체크리스트

| 항목 | 결과 |
|------|------|
| domain 레이어 Flutter/drift 의존 없음 | ✅ / ❌ |
| Repository 인터페이스 패턴 준수 | ✅ / ❌ |
| 원자적 트랜잭션 처리 | ✅ / N/A |
| TDD — UseCase 대응 테스트 존재 | ✅ / ❌ / N/A |
| TDD — DAO 대응 테스트 존재 | ✅ / ❌ / N/A |
| drift 패턴 (textEnum, references) | ✅ / ❌ / N/A |
| Riverpod @riverpod 코드 생성 사용 | ✅ / ❌ / N/A |
| 디자인 토큰 사용 (raw hex 없음) | ✅ / ❌ / N/A |

---

## 개선 제안

[전반적인 코드 품질 개선을 위한 제안 2-3가지]
```

### 4. 리포트 출력

서브에이전트의 리포트를 그대로 사용자에게 전달한다.
종합 판정이 `FAIL`이면 Critical 항목을 먼저 수정할 것을 강조한다.

### 5. After Hook — apply-review 자동 실행

리포트 출력 후 즉시 아래 훅을 실행한다.

## Extension Hooks

**Automatic Hook**: apply-review
Executing: `/apply-review`
EXECUTE_COMMAND: apply-review

## 주의사항

- 서브에이전트는 이 대화의 컨텍스트를 모른다. **모든 판단은 파일 내용에만 근거**한다.
- `dart analyze` 결과가 없으면 (Flutter 미설치 등) 해당 항목은 "실행 불가"로 표시한다.
- 생성된 파일 (`*.g.dart`, `*.mocks.dart`)은 리뷰에서 제외한다.
- 리뷰어는 코드를 수정하지 않는다. 발견 및 제안만 제공한다.
