---
name: React & Next.js Core Architecture Skill
description: >
  프론트엔드 생태계(React 19, Next.js App Router)에서 클라이언트 상태의 오염을 막고 컴포넌트 생태계의 렌더링을 지배하는 시니어 룰.
---

# ⚛️ React & Next.js Architecture Protocol

이 스킬 문서는 에이전트가 프론트엔드 환경에서 컴포넌트나 라우터를 작성할 때, 성능 저하(Re-rendering)와 컨텍스트 오염을 막기 위한 시니어 프론트엔드 아키텍트의 무자비한 법전입니다.

## 1. "Use Client" 격리 수용소 (The Boundary of State)
Next.js의 위대한 무기인 서버 사이드 렌더링(RSC, React Server Component) 생태계를 완전히 박살 내버리는 행위를 엄단합니다. 에이전트는 귀찮다는 이유로 최상위 부모 컴포넌트나 `layout.tsx`, `page.tsx`에 `'use client'`를 남발해서는 안 됩니다.

- ❌ 금지 사례: 전체 페이지 블록 상단에 지시어 선언 (`Suspense`나 `fetch`의 이점을 영구 박탈시킴)
- ✅ 강제 원칙: 상태(`useState`, `useReducer`), 생명주기(`useEffect`), 또는 이벤트 리스너(`onClick`)가 반드시 필요한 버튼 쪼가리, 모달, 폼 등 **"가장 작고 말단에 위치한 단위 컴포넌트(Leaf Component)"로만 코드를 찢어낸(Splitting) 다음**, 그 조각 파일 내부에만 `'use client'`를 격리 선언하십시오.

## 2. TailwindCSS 인라인 떡칠 금지 (The Tailwind Componentization)
아무리 뛰어난 유틸리티 클래스라도 요소 하나에 20줄이 넘어가는 클래스를 인라인으로 작성하면 코드 가독성이 0(Zero)으로 수렴합니다.

- ❌ 금지 사례: `className="flex flex-col items-center justify-center pt-10 pb-5 w-full bg-red-500 hover:bg-red-700 transition-all duration-300 md:flex-row shadow-lg sm:p-2 sm:m-1..."`
- ✅ 대안 강제: 요소 하나의 Tailwind 클래스가 5단어를 초과하거나 조건부 렌더링 로직(`isValid ? 'bg-red-500' : 'bg-green-500'`)이 길어질 조짐이 보이면, 즉시 코딩을 멈추고 `cva(class-variance-authority)`, `clsx`, 혹은 컴포넌트 밖의 정적 상수로 스타일을 추상화하여(Extracted) 뷰 계층의 가독성을 최우선으로 확보하십시오.

## 3. Prop Drilling 연쇄 살인 (The Context Enforcer)
부모에서 자식으로 의존성 상태(State)나 콜백(Callback) 함수를 넘겨주는 행위 자체는 정당하나, 그 깊이가 3단계를 넘어가는 '드릴링(Drilling)' 현상을 인스턴스의 낭비이자 코드 악취(Smell)로 규정합니다.

- ❌ 금지 사례: `<Grandparent state={state}>` -> `<Parent state={state}>` -> `<Child state={state}>` -> `<Target state={state}>`
- ✅ 아키텍트의 솔루션: 자식 컴포넌트의 뎁스가 3단계를 초과하여 속성을 내려꽂아야 하는 설계가 도출되면, 즉시 작업을 취소하십시오. **이때 가장 먼저 해당 상태가 URL Query로 치환 가능한지(Stateless Architecture 참조) 격상 평가를 수행하십시오.** 뒤로 가기나 공유가 필요 없는 순수 내부 UI 상태(예: 모달 렌더링 여부)에 한해서만 1) React Context API(기본) 2) Zustand 혹은 Jotai (글로벌 상태) 중 하나를 선택하여 상태를 우회(Bypass) 주입하는 완벽한 설계를 다시 제시하십시오.

## 4. 네트워크 경계 넘나들기 (The Serialization Boundary)
Next.js의 서버 컴포넌트(Server)에서 클라이언트 컴포넌트(Client)로 데이터를 Props로 넘기는 행위는 프로세스(Node.js -> Browser)를 횡단하는 값비싼 직렬화(Serialization) 과정을 수반합니다.

- ❌ 금지 사례: DB에서 갓 꺼낸 ORM 객체 덩어리 인스턴스 전체나, 사용하지도 않을 50개의 필드가 담긴 거대한 DTO 배열을 통째로 클라이언트 컴포넌트에 Props로 욱여넣는 행위. (Data Leak 및 직렬화 에러 유발)
- ✅ 강제 원칙: 서버-클라이언트 경계(Network Boundary)를 넘을 때는, 반드시 **클라이언트 렌더링에 필요한 최소한의 스칼라(Scalar) 필드값만 원시 타입(Primitive: string, number, boolean)으로 매핑(Mapping) 내지 DTO 변환**하여 페이로드 크기를 90% 이상 압축해 넘기십시오.
