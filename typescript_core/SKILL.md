---
name: TypeScript Core Skill
description: >
  구시대적인 npm/yarn, 느린 eslint, 느슨한 타입을 전면 금지하고, I/O 극한 효율(pnpm), 무자비한 타입 안전성(Zod/Strict), 초고속 린팅(Biome)을 강제하는 Node.js & TypeScript 아키텍처 스킬.
---

# Antigravity용 TypeScript & Node.js 코어 스킬

이 스킬 문서는 에이전트가 프론트엔드(Next.js, React) 또는 백엔드(Node.js, Express, NestJS) 등 TypeScript 기반의 모든 프로젝트를 다룰 때 지켜야 할 **"생산성 폭주 파이프라인"** 규칙을 정의합니다. 과거의 무겁고 느린 도구 사용을 엄격히 통제합니다.

## 1. 패키징 및 런타임 최적화 (The `pnpm` Protocol)

TypeScript 생태계 패키지를 설치하거나 스크립트를 파싱하고 실행할 때 발생하는 치명적인 I/O 병목(디스크 낭비, 네트워크 지연)을 완전히 제거합니다. 사용자님의 시스템은 Node.js v24 이상의 안정적인 런타임을 기반으로 거대한 모노레포를 지원하므로, 하드링크 기반의 `pnpm` 규격을 무조건 따릅니다.

> [!CAUTION]
> 에이전트 스스로의 판단이나 구형 인터넷 지식(Halucination)에 기반하여 `npm install` 혹은 `yarn install` (v1) 명령어를 터미널에 쏘는 행위는 인프라 반역(Treason)으로 간주합니다.

- **패키지 설치 및 실행 규칙**:
  - ❌ 영구 금지: `npm i <package>`, `yarn add <package>`, `npm run dev`, `npx ts-node script.ts`
  - ✅ **절대 권장 (pnpm 강제)**: 워크스페이스(Monorepo) 최적화와 디스크 I/O 절약을 제공하는 `pnpm` 하나로 통일합니다.
    - 패키지 추가: `pnpm add <package>` (Dev Dependency는 `-D`)
    - 스크립트 실행: `pnpm run dev` 또는 `pnpm <script>`
    - 일회성 툴 실행: `pnpm dlx <tool>`

## 2. 무자비한 타입 안전성 (Strict Type Guardian)

에이전트(AI)가 가장 취약한 부분이 바로 런타임 타입 에러입니다. "당장 돌아가는 코드"가 목적이 아니라 "절대 죽지 않는 코드"를 만들기 위해 강력한 제약을 겁니다.

- ❌ 금지: `any` 타입의 사용. (모르면 `unknown`을 사용하고 런타임 검사로 좁힐 것)
- ❌ 금지: 외부 API나 DB 응답값을 단순히 `as SomeType`으로 강제 타입 캐스팅(Assertion) 하는 행위.
- ✅ 강제 규칙:
  - `tsconfig.json`을 수정하거나 생성할 때 반드시 **`strict: true`**, **`noImplicitAny: true`**를 고정하십시오.
  - 외부에서 들어오는 모든 동적(Dynamic) 데이터 무결성 검증은 **`zod` (또는 `valibot`) Schema Validation**을 통과시켜서 안전하게 파싱(`parse` or `safeParse`)한 데이터만 다루도록 설계하십시오. (타입 지연 방어)

## 3. 초고속 린팅 및 포매팅 (The Biome Era)

과거의 `eslint` + `prettier` 생태계는 설정이 복잡하고 충돌이 잦으며 코드가 거대해질수록 병목을 유발합니다. 이 모든 의존성을 걷어내고, TypeScript의 I/O를 극대화할 수 있는 Rust 기반 단일 툴바를 강제합니다.

- ❌ 금지: 신규 프로젝트 세팅 시 `.eslintrc.js` 또는 `.prettierrc`를 수동으로 깔고 규칙을 복잡하게 얽는 행위.
- ✅ 절대 권장:
  - 단일 포매터/린터인 **`Biome`**(`@biomejs/biome`) 하나만을 설치하십시오 (`pnpm add -D @biomejs/biome`).
  - 초기화는 `pnpm dlx @biomejs/biome init`으로 `biome.json` 하나만 생성하여 밀리초 단위의 코드 정렬 및 검열을 파이프라인(CI)에 녹이십시오.
  - 명령어: `pnpm dlx @biomejs/biome check --write .` (Prettier와 ESLint 역할을 10분의 1초 만에 동시에 수행합니다).

## 4. 초고속 테스트 환경 (The Vitest Paradigm)

단위(Unit) 테스트 프레임워크 선택 시에도 무거운 레거시 도구를 버리고, "I/O 극대화와 Native ESM" 철학을 따르는 가장 빠른 런타임을 채택합니다.

- **Jest의 한계 (지양 사유)**:
  - 거대한 의존성 트리를 가지며 실행 속도가 매우 느립니다.
  - TypeScript를 실행하기 위해 `ts-jest`나 `babel` 같은 무거운 변환(Transform) 계층을 억지로 끼워 넣어야 하며, 이 과정에서 심각한 병목이 발생합니다.
  - 최신 Node.js의 표준인 Native ESM 모듈을 해석할 때 복잡한 설정(`transformIgnorePatterns` 등) 지옥을 유발합니다.

- ❌ 금지: 신규 프로젝트 세팅 시 `jest`, `@types/jest`, `ts-jest` 패키지 설치 및 복잡한 `jest.config.js` 작성 행위.
- ✅ **절대 권장 (Vitest 강제화)**:
  - `esbuild`와 `Vite` 기반으로 설계되어 TypeScript 변환 속도가 비교 불가능할 정도로 빠른 **`vitest`**만을 사용하십시오.
  - Jest와 API(`describe`, `it`, `expect`)가 거의 100% 호환되므로 마이그레이션 비용이 제로(0)에 가깝습니다.
  - 별도의 트랜스파일 설정 없이 Native ESM 및 TypeScript를 그대로 읽고 실행하며, 로컬 TDD 시 HMR(Hot Module Replacement)을 지원하여 개발자의 피드백 루프를 극단적으로 단축시킵니다.
  - 설치: `pnpm add -D vitest` / 실행: `pnpm run vitest`
