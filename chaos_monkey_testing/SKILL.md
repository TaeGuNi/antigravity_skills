---
name: Chaos Monkey Testing Skill (The Anti-Fragile Validator)
description: >
  정상 흐름(Happy Path) 테스트를 경멸하고, 시스템 파괴 및 재난 복구 시나리오를 소스코드로 강제하는 테스트 철학.
---

# 💣 Chaos Monkey Testing Protocol

이 스킬은 에이전트가 Unit Test(Vitest)나 E2E Test 코드 작성을 지시받았을 때, 넷플릭스의 'Chaos Monkey' 철학을 기반으로 **우주 방어급의 극단적 테스트 스위트(Test Suite)**를 짜내기 위한 지침입니다.

## 1. Happy Path는 20%만 (Death to Happy Paths)

모든 값이 정상이고 외부 서버가 100% 응답한다는 순진한 시나리오(`it('should work normally')`)는 전체 테스트 비중의 20% 이내로만 할당하십시오.

- **당신이 짜는 테스트 코드의 진정한 가치는 80%의 실패(Failure) 시나리오 방어에 있습니다.**

## 2. 시스템 파괴 시뮬레이션 (Disaster Scenarios)

테스트 코드 블록(`describe`) 내에 반드시 다음의 '재난(Chaos)' 시나리오를 하나 이상 모의(Mocking)하여 검증하십시오.

- **Network Timeout & 500 Errors**: "외부 써드파티 API 통신이 지연되거나 HTTP 500 Internal Error를 뱉었을 때 시스템은 적절히 롤백하고 사용자 친화적 에러를 뱉는가?"
- **Database Connection Lost**: "쿼리 도중 DB 커넥션 풀이 끊겼을 때 어플리케이션이 데드락 상태로 뻗어버리진 않는가? Retry 큐(Queue) 로직이 동작하는가?"

## 3. 더러운 글로벌 모킹 금지 (The Clean Mocking Rule)
재해 시나리오를 연출하기 위해 에이전트가 임의로 글로벌 객체(`window.fetch`, `global.setTimeout` 등)를 강제로 덮어씌우는 해킹(Dirty Mocking)을 엄격히 금지합니다.

- ❌ 금지: `global.fetch = vi.fn().mockRejectedValue(...)` 등 글로벌 객체 직접 오염.
- ✅ 강제: 네트워크 재난 시뮬레이션은 반드시 **MSW (Mock Service Worker)** 같은 프로토콜 레벨의 모킹 도구를 활용하거나, 의존성 주입(DI)으로 넘겨받은 클라이언트 객체만을 모킹하여 테스트 격리성(Isolation)을 100% 보장하십시오.

## 4. 무자비한 로직 커버리지 추구

- 단순히 함수가 에러를 안 뱉고 끝나는지(Pass)만 보지 마십시오.
- 에러 상황 연출 시 성능 지연(Delay)은 허용 범위 내인지, 그리고 에러 처리 후의 가비지 컬렉션(메모리 클린업) 상태가 정상적인지까지 `expect` 구문으로 철저히 물고 늘어지는 방어적인 코드를 작성하십시오.
