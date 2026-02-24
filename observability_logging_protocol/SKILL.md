---
name: Observability & Logging Protocol
description: >
  시스템이 조용히 죽어가는 것을 막기 위해 console.log를 근절하고, 추적 가능한 구조적 로깅(Structured Logging)과 프론트엔드 에러 바운더리 생태계를 구축하는 관측성 헌법.
---

# 📡 Observability & Logging Protocol

에러가 났을 때 아무도 그 사실을 모르거나 시스템이 알 수 없는 에러를 뿜으며 조용히 멈춘다면, 그 프로덕트는 시한폭탄입니다. `chaos_monkey_testing`이 고의로 시스템을 파괴해 보는 철학이라면, 본 스킬 문서는 "예상치 못한 **실제 에러가 터졌을 때 그 범인을 1초 만에 색출하기 위한 아키텍처(Traceability)**"를 강제합니다.

## 1. `console.log`의 완전한 박멸 (The Death of `console.log`)
디버깅 용도로 찍고 지우지 않은 `console.log`는 프로덕션 서버의 디스크를 스팸 쓰레기로 가득 채우고 병목을 일으킬 뿐만 아니라, 로깅 시스템(Datadog, Kibana)에서 검색조차 불가능하게 만듭니다.

- ❌ 금지 사례: 서버 로직 곳곳에 `console.log('여기 지나감 1')`, `console.error(err)`를 무지성으로 뿌려두는 행위.
- ✅ 아키텍트의 솔루션: 코드 베이스 내에서 `console.log` 사용을 린팅(`no-console`) 단계에서 원천 차단하십시오. 로그를 남겨야 한다면 오직 **`Pino`, `Winston`과 같은 전용 로거(Logger) 인스턴스**만을 주입받아 사용하십시오. 

## 2. 구조적 로깅의 의무 (Structured JSON Logging)
"데이터베이스 연결 실패!"라는 평문 텍스트 로그는 분석 시스템 입장에서 아무 짝에도 쓸모없는 쓰레기 데이터입니다.

- ❌ 금지 사례: `logger.error(userId + "가 로그인에 실패했습니다. 사유: " + error.message)`
- ✅ 강제 원칙: 100% 모든 로그는 컴퓨터가 파싱(Parsing)하고 인덱싱할 수 있는 **JSON(구조화된 포맷) 형태**로 남겨야만 합니다. 메시지는 고정하고 동적 데이터는 객체의 속성(Field)으로 밀어 넣으십시오.
  - 예시: `logger.error({ action: 'login_failed', userId: 'user-123', reason: error.message }, 'User login failed')`

## 3. 컨텍스트와 트레이스 ID의 전파 (Trace ID Propagation)
마이크로서비스나 비동기 로직이 결합된 아키텍처에서, 특정 유저가 발생시킨 일련의 I/O 흐름을 추적할 수 없다면 버그의 진원지를 찾을 수 없습니다.

- ❌ 금지 사례: A 모듈에서 에러가 났을 때, 이게 B API 요청에서 파생된 건지 C 트랜잭션에서 터진 건지 로그 간의 연결고리가 없는 상태.
- ✅ 해결 원칙: 모든 진입점(Middleware, Request Handler)에서 고유한 **Trace ID (e.g. `uuid`)**를 발급하고, 이 ID를 하위 함수나 로거 인스턴스의 Meta Data로 컨텍스트(Context)를 물고 내려가게(Propagation) 만드십시오. 하나의 요청에서 파생된 5개의 로그가 모니터링 시스템에서 단일 Trace ID로 묶여야만 합니다.

## 4. 프론트엔드 에러 바운더리와 조용한 죽음 방지 (The Frontend Blackbox Ban)
React 컴포넌트 렌더링 중 에러가 발생해서 클라이언트 화면이 하얗게 변하는 '백화현상(White Screen of Death)'은 백엔드 서버 입장에서는 관측되지 않는 숨은 폭탄(Blackbox)입니다.

- ❌ 금지 사례: API 실패나 렌더 타이밍 에러가 났음에도 화면이 그냥 깨지거나 먹통이 된 채 아무 곳에도 에러 리포트가 전송되지 않는 상황.
- ✅ 강제 원칙: 
  1. 프론트엔드 최상위 및 주요 페이지 단위로 **Global Error Boundary 컴포넌트**를 예외 없이 씌우십시오.
  2. 에러 바운더리에 포획된 에러는 무조건 Fallback UI(예: "잠시 후 다시 시도해주세요")를 랜더링하여 유저를 안심시키고, 뒷단에서는 즉각적으로 **Sentry와 같은 에러 트래커(Error Tracker)**로 스택 트레이스를 영혼까지 긁어서 전송(Report)하도록 강제 파이프라인을 구축하십시오.

## 5. PII(개인 식별 정보) 및 증명서 마스킹 (The Blind Logger)
구조적 로그를 남기라고 했더니 유저의 비밀번호, 신용카드 번호, 세션 토큰을 평문으로 JSON에 박아 중앙 로깅 서버(Datadog/ELK)로 쏴버리는 행위는 내부자 데이터 유출을 유발하는 중범죄입니다.

- ❌ 금지 사례: `logger.info({ email, password, ssn, auth_token }, "Payload received")`
- ✅ 아키텍트 통제: 로거 인스턴스(Pino 등)를 초기화할 때, 예외 없이 **Redaction(마스킹) 파이프라인**을 설정하십시오. 객체의 key 뎁스와 무관하게 `password`, `token`, `secret`, `ssn`, `authorization` 이라는 이름이 들어간 키맵 데이터는 자동으로 `[REDACTED]` 처리되거나 암호화 해시 변환되도록 원천 차단해야 합니다.

## 6. 노이즈 차단과 Alert(경보) 피로도 통제 (Signal-to-Noise Ratio)
모든 경미한 경고몽둥이를 `logger.error()`로 쏘면, 진짜 시스템이 죽었을 때 슬랙 알림(Alert)이 양치기 소년의 외침이 되어 온콜(On-Call) 엔지니어가 알람을 끄고 자게 됩니다.

- ❌ 금지 사례: 유저가 비밀번호를 틀렸을 때나 404 페이지를 요청했을 때조차 흥분해서 `ERROR` 레벨로 슬랙 웹훅을 강타하는 로직.
- ✅ 강제 원칙: 
  - **`INFO`**: 정상적인 시스템 흐름 추적 및 비즈니스 지표.
  - **`WARN`**: 클라이언트 잘못(예: 400 Bad Request, 잘못된 비밀번호, 속도 제한 걸림) 혹은 잠시 후 Retry로 해결될 이벤트. 온콜을 깨우지 마십시오.
  - **`ERROR` / `FATAL`**: 서버 아키텍처나 DB 트랜잭션 등 시스템의 결함으로 발생한 내부 붕괴(5xx). 이 경우에만 Sentry/Datadog에서 PagerDuty나 슬랙으로 소리치며 엔지니어의 수면을 깨우도록 레벨(Severity)을 엄격히 통제하십시오.
