---
name: The Absolute Nomenclature & Structural Isolation Constitution
description: >
  모든 TS/JS 생태계에 적용되는 파일시스템 헌법. 쓰레기통 네이밍(utils) 금지, 완벽한 폴더 물리 격리 및 AST(ts-morph) 기반의 무자비한 리팩토링 철학.
---

# 🏛️ The Absolute Nomenclature & Structural Isolation Constitution (절대 네이밍 및 물리적 격리 헌법)

이 문서는 단순한 '권장 가이드라인'이 아닙니다. 이 스킬은 Antigravity 에이전트와 엔지니어가 모노레포 및 모든 TypeScript/Node.js 프로젝트에 코드를 기여할 때, 타협 없이 맹목적으로 따라야 하는 **절대적인 아키텍처 헌법이자 선악의 기준점**입니다. 
이 규칙을 약간이라도 벗어나는 코드 생성이나 파일 수정은 단 1 line이라도 가차 없이 거부되어야 합니다.

---

## 1. 병적인 네이밍 컨벤션 강제 (The Nomenclature Absolute)

어떤 상황에서도 "이름 짓기가 귀찮아서" 뭉뚱그려 네이밍하는 행위는 용납되지 않습니다. 모든 모듈과 파일명은 본인이 속한 **도메인(Domain)**과 감당하는 **역할(Role)**을 파일명만으로 100% 증명해야 합니다.

### 1) 백엔드 / 코어 패키지 (kebab-case.ts 명시화)

- Node.js, Express, Fastify, NestJS 등 백엔드 생태계에서는 특정 프레임워크의 룰을 따르더라도, **점(.)으로 완벽히 분리된 역할 명시**를 강제합니다.
  - ✅ 허용: `user.controller.ts`, `search-programs.constants.ts`, `logger.type.ts`
- ❌ **원천 금지**: `utils.ts`, `helpers.ts`, `common.ts` 따위의 '쓰레기통 네이밍'은 생성 자체를 금지합니다. 유틸리티가 필요하다면 `string-formatter.util.ts` 처럼 명확한 역할을 기입하십시오.

### 2) DTO 및 Type 계층 접미사 (Suffix) 헌법

- `src/dto/` 내부: 무조건 `[domain].dto.ts` (예: `auth.ts` -> ❌ / `auth.dto.ts` -> ✅)
- `src/types/` 내부: 무조건 `[domain].type.ts`
- `src/interfaces/` 내부: 무조건 `[domain].interface.ts`

### 3) 프론트엔드 (React/Next.js) 하이브리드 명명법의 확장

- **UI 컴포넌트 (`*.tsx`)**: CI(Linux) 대소문자 무시 치명적 버그를 막기 위해 파일명은 무조건 `kebab-case.tsx` (`chat-fab.tsx`), 내부 export 함수는 무조건 `PascalCase` (`export const ChatFab`) 로 작성합니다.
- **Hooks & Context (`*.ts` / `*.tsx`)**: 
  - 커스텀 훅: `use-payment.ts` 파일명 안에 `export const usePayment` 강제.
  - Context API: `payment.context.tsx` 파일명 안에 `export const PaymentContext` 강제.
  - 리덕스/Zustand: `payment.store.ts` 파일명 안에 `export const usePaymentStore` 강제.

### 4) 테스트 응집도 (Co-location) 규칙

- `tests/` 또는 `__tests__/` 폴더를 따로 만들어 테스트 코드를 숨기는 행위는 **엔터프라이즈 레벨의 적폐**입니다.
- 모든 유닛 테스트 파일은 원본 비즈니스 로직과 **정확히 동일한 디렉토리**에 위치해야 하며, 파일명은 반드시 `[원본파일명].spec.ts` 여야 합니다. (예: `programs.service.ts` -> `programs.service.spec.ts`)

---

## 2. 물리적 계층 격리 및 Zero-Trust (Physical DDD & Zero-Trust Eviction)

하나의 파일 안에 글로벌 도메인 구조체(Interface), 로컬 프롭스(Type), 그리고 비즈니스 로직이나 Zod 스키마가 더럽게 섞여 있는 꼴을 절대 용납하지 않습니다.

### 1) 글로벌 Interface 방출 (Eviction)과 로컬 Type의 공존 (Co-location)

- **로컬 Props/Type**: React 컴포넌트(`payment-modal.tsx`) 내부에서 **오직 해당 컴포넌트만 사용하는 Props UI 인터페이스/타입**은 컴포넌트 파일 바로 위에 작성하는 응집도(Co-location)를 절대 허용합니다. (굳이 내쫓지 말 것).
- **글로벌 도메인 Interface**: 반면, 여러 컴포넌트와 비즈니스 서비스에 걸쳐 사용되는 "DB 엔티티와 비즈니스 도메인 명세 구조체(`User`, `Payment` 등)"는 **반드시 `src/interfaces/` 폴더로 물리적 방출(Eviction)** 되어야 합니다.
- 순수 원시 단위 타입 결합나 Enum은 `src/types/` 에만 둡니다.

### 2) Zero-Trust DTO 파이프라인 (Zod Enforcement)

- `src/dto/` 공간은 무의미한 TypeScript 인터페이스를 선언하는 구시대적 껍데기가 아닙니다.
- 프론트나 백에서 API 너머로 들어오는 모든 I/O 데이터는 악성 페이로드(XSS, Prototype Pollution)로 단정합니다. DTO 파일은 오로지 **`Zod (z.object)`나 `Valibot` 런타임 스키마 방어벽으로 구축해야 합니다.**
- 검증 로직 없이 껍데기만 남은 순수 타입 DTO는 즉각 `interfaces/` 영역으로 쫓아내십시오.

### 3) 프레임워크 스탠스: 무거운 OOP에 대한 혐오

- 우리 생태계는 상태(State) 오염의 주범인 무거운 Class 기반 상속과 런타임 데코레이터(`class-validator`)를 생태계 악성 코드로 취급하며, **순수 함수(Pure Function) + Closure Factory** 중심의 함수형(Functional) 패러다임을 강제합니다.
- 단, `NestJS` 아키텍처 위에서 강제로 작동해야 하는 백엔드의 경우, 프레임워크 뼈대인 Class 기반 DI와 Decorator 컨테이너는 존중하되, 검증 계층(Validation)만큼은 `class-validator`를 전부 찢어버리고 `Zod Validation Pipe`로 교체하여 타협합니다.

---

## 3. 무결성과 불도저식 리팩토링 통제 (Integrity & Bulldozer Strategy)

파일 수정 중 100개의 TS 참조 에러가 터졌다고 해서, 에이전트가 변명을 핑계로 구시대적 코드를 덮고 도망가는 것을 사살(Kill)합니다.

- **De-monolith (통짜 모듈 파편화)**: 언어팩(i18n), Router Index, 설정 파일 등이 통짜 JSON/TS로 300줄을 넘어가는 순간 "괴물"이 됩니다. 그 즉시 로더 로직을 재설계하더라도 모듈을 조각조각 해체(`baumann-terms.ko.json` 등) 하십시오.
- **불도저 리팩토링 (Bulldozer Refactoring)**: 아키텍처 헌법을 지키느라 수십 개의 파일에 에러 붉은 줄이 쳐지면 하나씩 타고 들어가 수동으로 타협하는 것이 아니라, `ts-morph`, `jscodeshift`, `Biome API` 와 같은 **TypeScript 네이티브 AST(추상 구문 트리) 스크립트 도구**를 활용해야 합니다.
- 타입 안전성 및 컴포넌트 트리를 파싱하여 한 번에 수백 개의 레거시를 분쇄하고, 빌드(`exit code 0`)가 초록불이 될 때까지 밀어붙이는 것이 이 헌법의 최종 목적입니다. (정규식이나 파이썬 파서 사용 금지).
