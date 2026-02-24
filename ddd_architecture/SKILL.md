---
name: Domain-Driven Design (DDD) & Clean Architecture Protocol
description: >
  코드의 부패(Spaghetti)를 막고, View-Business-Data 계층의 완벽한 분리를 강제하는 시니어 아키텍처 스킬.
---

# 🏛️ Domain-Driven Design (DDD) & Clean Architecture Protocol

이 스킬 문서는 에이전트가 코드를 생성하고 구조를 잡을 때, 프레임워크나 외부 라이브러리에 종속되지 않는 **"순수한 비즈니스 모델(Domain) 중심의 설계"**를 강제하기 위한 절대 규칙입니다. 어플리케이션이 거대해질수록 유지보수 비용을 0(Zero)으로 수렴하게 만드는 시니어급 아키텍처 법전입니다.

## 1. 전권 계층 붕괴 절대 금지 (The Layer Separation Rule)
단일 파일(특히 UI, Controller 등) 내부에 서로 다른 관심사가 뒤섞이는 스파게티 코딩을 "아키텍처 인프라 테러"로 규정합니다. 에이전트가 코드를 수정할 때, 다음의 관심사 분리(SoC, Separation of Concerns)를 완벽하게 지켜야 합니다.

- ❌ 금지 사례 (UI 계층 오염): React 컴포넌트(`page.tsx`, `Component.tsx`) 또는 HTTP 라우터 컨테이너 내부에서 직접 SQL 질의(`Prisma / Query`)를 수행하거나 외부 API 통신 로직(`fetch`, `axios`) 인스턴스를 직접 때려 넣는 행위.
- ✅ 강제 원칙 (계층화):
  1. **Presentation (UI/Controllers)**: 오직 들어온 요청(HTTP/Interaction)을 받아 파라미터를 넘기고, 결과를 `Render` 혹은 반환(Response)하는 역할만 담당합니다. 연산 금지.
  2. **Domain / Service**: 애플리케이션의 핵심 "비즈니스 로직(결제, 승인, 상태 변이 등)"을 담당합니다. 순수 함수와 타입으로만 이뤄져야 합니다.
  3. **Repository / Infrastructure**: 외부 통신(API, DB, Message Queue, ORM)을 전담합니다.

## 2. 도메인 오염 방지 (The Framework Agnostic Rule)
" 핵심 도메인 로직은 프레임워크(React, Next.js, Express, ORM)가 내일 망해서 다른 것으로 대체되어도 단 한 줄도 수정되지 않아야 한다. "

- 애플리케이션의 뼈대가 되는 `Entity`, `Value Object`, `Domain Service` 로직에는 특정 프레임워크나 데이터베이스(예: `import { prisma } from 'prisma'`) 의존성을 직접 `import` 하는 것을 극도로 경계하십시오.
- 외부 의존성은 반드시 인터페이스(Interface/Type) 기반의 의존성 주입(Dependency Injection) 또는 포트 및 어댑터 패턴(Hexagonal)을 통해 느슨하게 결합(Loose Coupling) 시키십시오.

## 3. 프레임워크 스켈레톤의 존중 (Embrace the Skeleton)
DDD를 적용한다고 해서 프레임워크(Next.js App Router, NestJS 등) 고유의 아키텍처 생태계와 라우팅 규칙을 거스르는 "과도한 헥사고널 오버엔지니어링"을 강행해서는 안 됩니다.

- ✅ 조화로운 설계: Next.js의 `app/` 라우팅 폴더 안에서는 철저하게 프레임워크의 룰(View, Layout)을 따르되, 라우트 핸들러가 호출하는 함수는 프레임워크와 무관한 독립적인 `src/domain` 또는 `src/application` 폴더의 클래스/함수를 임포트하여 사용하는 형태(Adapter Pattern)로 융합하십시오.

## 4. 거대 함수 파괴자 (The SRP Enforcer)
하나의 함수, 하나의 클래스가 2가지 이상의 행동 묘사를 한다고 판단되면 즉시 리팩토링의 대상이 됩니다.

- ❌ 금지: `createUserAndSendEmailAndCreateLog()`
- ✅ 행동 지침: 함수 길이가 30줄이 넘어가거나 주석으로 "여기부터 이메일 전송 파트", "여기부터 회원가입 파트"라고 구역이 나뉘는 냄새(Code Smell)를 풍긴다면, 단일 책임 원칙(SRP)에 입각하여 과감히 3개의 개별 함수(`createUser`, `sendWelcomeEmail`, `auditAction`)로 파편화(Splitting) 하십시오.
- 모든 객체/함수는 단 하나의 변경 이유(Single Reason to Change)만을 가져야 합니다.
