---
name: Playwright Ref-Based Token Reduction Protocol (The "Agent-Browser" Methodology)
description: A protocol to reduce AI token consumption by 90% during Playwright testing by converting complex HTML DOMs into compact, reference-based semantic maps (Refs).
---

# 🎭 Playwright Ref-Based Token Reduction Protocol (The "Agent-Browser" Methodology)

> **엔터프라이즈 AI E2E 테스트를 위한 극강의 컨텍스트 압축 및 강건성(Robustness) 헌법 (Ultimate Masterpiece + ROI Optimization)**

이 문서는 AI 에이전트가 Playwright를 사용하여 웹 브라우저를 탐색하고 테스트 코드를 작성할 때 토큰(Token) 사용량을 극단적으로 줄이면서도 정확도를 높이는 **"참조(Ref) 기반 렌더링 프로토콜"**을 규정합니다. 

단일 페이지의 전체 DOM을 AI에게 전송하는 멍청한 짓(HTML Dumps)을 "반역"으로 금지하고, 오직 의미 있는 **상호작용 노드(Interactive Nodes)**만을 압축된 Map 형태로 전송 및 제어합니다. 최신 웹 아키텍처(SPA, Shadow DOM, 모달 오버레이)를 돌파하며, 결과 검증(Assertion) 없는 맹목적 클릭과 **토큰 폭발(Token Explosion)**을 무자비하게 통제합니다.

---

## 🔥 1. 철학: DOM Noise Annihilation (모든 HTML을 버려라)

**에이전트는 원형의 HTML 구조(`document.innerHTML` 또는 `locator.innerHTML()`)를 절대 읽어서는 안 됩니다.**

- **절대 금지:** 전체 텍스트 추출, CSS Selector 의존 방식의 추적.
- **유일한 진리:** `Snapshot + Refs` 시스템. 브라우저 컨텍스트의 Main & Shadow DOM 경계를 완벽히 투과하여 오직 "실제로 화면에 보이고 인간이 클릭/입력할 수 있는 요소"만을 필터링하고, 가벼운 레퍼런스 ID(`@e1`, `@e2`)를 부여하여 AI에게 짧은 요약본만 넘깁니다.

---

## 🕵️ 2. 정찰 후 타격 패턴 (Reconnaissance-then-action)
동적 웹앱(Dynamic Webapp)을 다룰 때 AI 에이전트는 절대 눈먼 상태에서 예측만으로 클릭을 남발해서는 안 됩니다.

1. **Reconnaissance (정찰)**: 페이지 이동(`page.goto`) 또는 조작 후, **반드시 `page.wait_for_load_state('networkidle')`** 을 대기하여 모든 자바스크립트 렌더링이 끝날 때까지 숨을 죽이십시오.
2. **Scan**: 유휴 상태가 되면 그제서야 DOM 추출 맵(`generateRefMap`)을 실행하거나 스크린샷을 찍어 화면의 렌더링된 최종 상태를 읽어들이십시오.
3. **Action (타격)**: 확인된 `[data-agent-ref]` ID를 사용하여 정확하게 타격(클릭/타이핑)하십시오.

❌ **금지**: `networkidle` 대기 없이 즉시 DOM을 파싱하려 들거나 화면에 렌더링되지도 않은 요소를 예측만으로 클릭하려는 행위.

---

## 🏗️ 3. 아키텍처: The "Shadow-Piercing Ref Injector" Pattern

대형 상용 웹사이트(쿠팡, 아마존 등)에서 수천 개의 링크가 수집되어 **토큰 절감 목표가 박살 나는 현상(Noise Explosion)**을 방지하기 위해, 요소 수집 상한선(Max Limit)이 적용된 최적화 스크립트를 주입합니다.

### 단계 1: DOM 추출 및 Ref 주입 스크립트 실행
에이전트는 브라우저 렌더링 유휴 상태(`networkidle`)에서, 정밀 힌트(Hints)와 수집 허들(Limit 150)이 결합된 스크립트를 실행해야 합니다.

**[⚠️ 컨텍스트 윈도우 보호 (Token Saving Lazy Loading)]**
이 스크립트 소스는 토큰 절약을 위해 이 문서에 포함되어 있지 않습니다.
실제 브라우저 테스트 코드 작성이 필요할 때만 `view_file` 도구를 사용하여 아래 경로의 핵심 파서를 런타임에 읽어와서 파악하십시오:
👉 **가져올 파일 절대 경로**: `/Users/jay/.gemini/antigravity/skills/playwright_ref_protocol/references/ref_injector.js`
(에이전트는 필요할 때 이 파일을 단 한 번 읽은 후 해당 로직을 `page.evaluate`에 주입하여 사용합니다.)

---

## 🎯 3. 단계 2: 원자적 Abstraction 및 검증 (Action & Assertion)

에이전트는 맵의 상호작용 텍스트만 보고 대상 Ref를 클릭합니다. 단, SPA 렌더링의 잦은 실패를 피하기 위해 **개별 테스트 코드에 더러운 try-catch를 덕지덕지 바르지 않고, 프로젝트 내부에 구축된 `AgentHelper (Wrapper)`를 사용**합니다.

```typescript
// ❌ 금지된 안티 패턴 (더러운 보일러플레이트 코드 폭발)
try {
   await page.locator('[data-agent-ref="@e1"]').click();
} catch (e) {
   // 스크립트 다시 부르고... 다시 찾고... (코드 읽기 힘들어짐)
}

// ✅ 1. 권장 패턴: 프로젝트 내부 유틸리티 래퍼 사용 (에이전트가 테스트 짤 때 호출)
import { refAction } from '../tests/utils/agentHelper';

// refAction 함수 내부에서 [data-agent-ref] 클릭 시도, 타임아웃/Obscured 에러 시
// 자동으로 generateRefMap() 재호출 후 1회 한정 Retry를 수행하도록 캡슐화되어야 함.
await refAction(page).click('@e1');
await refAction(page).fill('@e2', 'Antigravity Protocol');

// ⚠️ 2. [가장 강력한 강제 규정] 조작 후 결과 검증(Assertion) 필수
// Target을 조작했다면 무의미하게 넘어가지 말고 행위의 결과를 `expect` 하라.
await expect(page).toHaveURL(/.*dashboard/); 
// 또는
// const newMap = await page.evaluate(generateRefMap);
// expect(newMap).toContain('Welcome Dashboard');
```

---

## � 4. 무자비한 토큰 경찰 (The Token Police)

- **MAX_ELEMENTS 폭발 경고:** 만약 `refMap`에 `[Warning: Max Limits Hit]` 문구가 찍혔다면? 인간이 감당 못할 수만 개의 돔 요소를 한 큐에 읽으려는 오만을 버리십시오. 상위 부모 컨테이너(예: 특정 모듈)로 Scope를 좁혀서 요소들을 수집(`traverse(document.querySelector('.target-area'))`)하여 압축률 90%를 견지하십시오.
- **HTML 원형 반환은 범죄:** `page.content()`는 어떠한 경우에도 로깅/반환 불가.
- **디버깅의 최후의 보루:** 힌트 맵(Map)으로도 도저히 풀리지 않는 렌더링 에러/트랩은, 토큰 제로의 **스크린샷 캡쳐(`page.screenshot()`)**를 Artifact에 남겨 인간에게 육안 검토를 요청하십시오.

> **에이전트 명령 복종 합의:** 개발자가 TDD, E2E 로직, 스크래퍼를 요구할 시 AI는 무조건 이 컨텍스트 압축 헌법(Ref Map)을 `page.evaluate`에 주입하여 시작한다. "전체 코드를 넘겨라"는 요구를 영원히 금지한다.
