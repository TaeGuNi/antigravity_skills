---
name: Stateless Architecture Protocol (The URL & JWT Paradigm)
description: >
  프론트엔드와 백엔드를 막론하고 '상태(State)'가 가져오는 부작용과 확장성 저하를 원천 차단하는 Stateless(무상태) 지향 설계 헌법.
---

# ☁️ Stateless Architecture Protocol

이 스킬 문서는 애플리케이션의 클라우드 네이티브(Cloud-Native) 확장성을 보장하고, 에러의 추적 가능성을 극대화하기 위해 에이전트가 코드를 작성할 때 **모든 형태의 '상태(State)'를 파괴하거나 외부로 위임**하도록 강제하는 수석 아키텍트의 룰셋입니다.

## 1. 프론트엔드: URL은 유일한 진리다 (URL as the Source of Truth)
React 환경에서 습관적으로 `useState`나 `useEffect`를 선언하여 사용자 입력이나 현재 징후를 메모리에 가두는 행위를 경멸합니다.

- ❌ 금지 사례: 현재 선택된 탭(Tab), 검색어(Search Keyword), 페이지 번호(Pagination)를 컴포넌트 내부의 `useState`로 관리. (새로고침 시 증발, 공유 불가, 서버 렌더링 불가)
- ✅ 강제 원칙: UI의 상태를 결정짓는 요인들은 무조건 **URL Query Parameters (`?tab=profile&page=2`)**로 승격시키십시오. 이를 통해 Next.js 서버 컴포넌트(RSC)가 브라우저 개입 없이도 완벽한 최초 HTML을 그려낼 수 있도록 통제권을 프레임워크와 라우터에 반납해야 합니다.

## 2. 백엔드: 메모리 상태 의존 금지 (Zero In-Memory State)
API 서버가 컨테이너 서빙, 서버리스(Serverless, AWS Lambda 등), 혹은 다중 포드(K8s)로 스케일 아웃될 때 서버 터짐을 유발하는 모든 in-memory 꼼수를 금지합니다.

- ❌ 금지 사례: 세션 스토토어에 로그인 정보 저장, 글로벌 변수(`let cache = {}`)를 활용한 서버 메모리 캐싱.
- ✅ 강제 원칙: 사용자 식별은 완전히 독립적인 검증이 가능한 **JWT(JSON Web Token)** 기반으로 구성하며, 캐싱이 필요하다면 반드시 영속성이 보장되는 외부 인프라(Redis 등)나 CDN 에지(Edge) 레벨로 위임하여, API 서버 자체는 언제든지 죽이고 새로 띄워도 클라이언트가 전혀 영향을 받지 않는 궁극의 Stateless를 달성하십시오.

## 3. 오퍼레이션의 멱등성 보장 (Idempotent by Default)
API 로직을 짤 때 클라이언트의 네트워크 단절이나 재시도(Retry) 폭격에 시스템 데이터가 오염되지 않아야 합니다.

- ❌ 금지 사례: 결제 승인 API 호출 시, 중복 호출 체크 없이 무조건 `amount += 100` 처리.
- ✅ 강제 원칙: 중요한 상태 변경 로직은 같은 요청을 10번, 100번 날리더라도 언제나 결과가 한 번 호출된 것과 동일하게 유지되는 **멱등성(Idempotency)**을 가지도록 설계하십시오. (예: `transaction_id` 기반 중복 체크, UPSERT 문법 강제)
