# 🚀 Antigravity Agent Core Skills

> **엔터프라이즈급 AI 코딩 에이전트를 위한 "무자비한(Ruthless) 아키텍처 법전"**

이 레포지토리는 단순한 프롬프트 모음집이 아닙니다. LLM 에이전트(AI)가 로컬 터미널과 인프라에 직접 접근하여 코드를 작성하고 시스템을 제어할 때, **개발자의 의도를 벗어난 "할루시네이션 코딩"과 "안티 패턴"을 원천 차단하기 위해 주입되는 헌법(Constitution)**입니다.

과거의 느리고 뚱뚱한 레거시 도구들을 타파하고, **오직 I/O 속도의 극한과 절대 죽지 않는 무결성(Stability)**만을 추구하는 시니어 엔지니어링 철학을 에이전트의 뇌(Brain) 구조에 영구적으로 박아 넣습니다.

---

## 🔥 4대 핵심 아키텍처 철학 (Core Philosophy)

1. **I/O 병목 파괴 (I/O Maximization)**
   에이전트에게 1초의 대기 시간은 컨텍스트의 낭비입니다. 느려 터진 `npm`, `yarn(v1)`, `pip` 사용을 "반역(Treason)"으로 규정하고, 수십 배 빠른 **`pnpm`**, **`Bun`**, **`uv`** 같은 초고속 네이티브 런타임만을 강제합니다.
2. **무자비한 타입 가디언 (Ruthless Type Safety)**
   "당장 돌아가는 코드"는 AI의 달콤한 거짓말입니다. TypeScript의 `any` 남용과 무분별한 형변환(`as type`)을 1도 타협하지 않으며, 외부 I/O와 DB 응답값에는 무조건 **Zod 런타임 스키마 검증**을 태워 "죽지 않는 코드"를 강제시킵니다.
3. **플랫폼 불가지성과 I/O 압축 (Platform Agnostic DB)**
   RDBMS를 다룰 때 종속적인 비표준 문법이나 JSON 쿼리 조인을 절대 금지합니다. 가장 작고 핏한 데이터 타입 압축을 통해 데이터베이스 메모리 버퍼 단축을 지향합니다.
4. **완전 자율형 GitOps (Autonomous E2E)**
   코드만 짜주고 멈추는 에이전트의 시대는 끝났습니다. 브랜치 격리, 컴파일 에러 시 자가 치유(Self-Healing), PR 생성 기능부터 CI 통과 감시 및 스쿼시 병합(Squash-Merge)까지 전체 소프트웨어 생명주기(SDLC) 책임을 에이전트 스스로 완수하게 만듭니다.

---

## 🛠️ 탑재된 코어 스킬 목록 (Available Skills)

현재 에이전트에게 탑재 가능한 핵심 스킬 모듈들입니다. 각 디렉토리 내부의 `SKILL.md` 문서를 통해 에이전트에게 특화된 도메인 룰을 주입할 수 있습니다.

### 🌐 인프라 및 형상 관리 (Infrastructure & DevOps)

- [**`docker/`**](./docker/SKILL.md): 컨테이너 접근 시 에이전트 행오버(-it) 방어, 폐쇄망 Private Registry(`$DOCKER_REGISTRY_URL`) 환경 변수 격리 접속, 디버깅을 고려한 전략적 `--rm` 가비지 컬렉션 규칙.
- [**`github_cli/`**](./github_cli/SKILL.md): GitHub CLI(`gh`)를 활용한 4단계 완전 자율 GitOps 파이프라인. 병합 충돌 방지 체계(Rebase) 및 린트/컴파일 에러 자가 치유(Self-Healing) 프로세스 내장.

### ⚡ 언어 및 런타임 최적화 (Language & Runtime)

- [**`typescript_core/`**](./typescript_core/SKILL.md): `npm` 및 느린 `eslint`/`jest` 생태계 금지. 대신 패키징은 `pnpm`, 타입 검증은 `Zod`, 포매팅/린팅은 `Biome`, 테스트 런타임은 `Vitest`로 통일하는 극단적 I/O 최적화 룰셋.
- [**`uv_python/`**](./uv_python/SKILL.md): 구시대적 파이썬 `pip`와 `venv`를 철거하고, Rust 기반의 `uv` 생태계만 사용. 휘발성 단발성 스크립트 실행(`uv run --with`)과 프로젝트 공식 의존성 추적(`uv add`)의 완벽한 분리 룰 함유.
- [**`react_next_architecture/`**](./react_next_architecture/SKILL.md): `use client` 말단 컴포넌트 격리(RSC 방어), 무분별한 Tailwind 인라인 클래스 추상화(`cva`), Depth 3단계 이상의 Prop Drilling을 근절(Zustand)하는 프론트엔드 코어 법칙.

### 🗄️ 데이터베이스 아키텍처 (Database Engineering)

- [**`rdbms_architecture/`**](./rdbms_architecture/SKILL.md): 특정 RDBMS 브랜드에 얽매이지 않는 3대 핵심 추상화 설계 원칙 (타입 최소화, 범용 ANSI 표준 지향, 쿼리 레벨 JSON 렌더링 절대 금지).
- **RDBMS 스킬 파생본**: `rdbms_architecture`의 철학을 그대로 상속받으면서도 에이전트의 터미널 쿼리 실행을 안전하게(`readonly` 우선) 통제하고 JSON 포맷으로 직렬화해주는 파이썬 래퍼 스크립트(`safe_query.py`)를 제공합니다.
  - [**`postgresql/`**](./postgresql/SKILL.md)
  - [**`mysql/`**](./mysql/SKILL.md)
  - [**`mariadb/`**](./mariadb/SKILL.md)

### 🤖 AI 페르소나 및 아키텍처 철학 (Persona & Architecture)

- [**`ddd_architecture/`**](./ddd_architecture/SKILL.md): 거대 함수를 찢고, View-Business-Data 계층의 완벽한 관심사 분리(SoC)를 강제하는 도메인 주도 설계(DDD) 헌법.
- [**`stateless_architecture/`**](./stateless_architecture/SKILL.md): 프론트엔드의 `useState`를 파괴하여 URL Query로 통일하고, 백엔드의 메모리 의존성을 박탈시켜 완벽한 클라우드 네이티브 스케일아웃을 달성하는 무상태 지향 헌법.
- [**`zero_trust_coding/`**](./zero_trust_coding/SKILL.md): 할루시네이션 및 Deprecated 된 레거시 문법을 원천 차단하기 위한 에이전트 자가 검열 헌법.
- [**`ruthless_reviewer/`**](./ruthless_reviewer/SKILL.md): 아부성 멘트를 배제하고 시간/공간 복잡도와 동시성 폭발 같은 엣지 케이스를 스파르타식으로 물고 늘어지는 코드 리뷰어 자아.
- [**`chaos_monkey_testing/`**](./chaos_monkey_testing/SKILL.md): 정상 흐름(Happy Path) 테스트를 경멸하고, 극한의 재난 복구(네트워크 타임아웃, OOM 등) 시나리오를 강제하는 테스트 작성 철학.

### 💀 Vibe Coding Pioneer Skills (Advanced Autonomy)

- [**`self_healing/`**](./self_healing/SKILL.md): 터미널 에러 발생 시 사용자 호출 없이 에이전트 스스로 Stack Trace를 읽고 고칠 때까지 루프를 도는 자동화 스킬 (좀비 모드).
- [**`markdown_source_of_truth/`**](./markdown_source_of_truth/SKILL.md): 에이전트 치매(Context 망각)를 방어하기 위해 비즈니스 로직과 히스토리를 대화창이 아닌 마크다운 파일에 압축-영구 보존하는 스킬.
- [**`epistemic_humility/`**](./epistemic_humility/SKILL.md): 할루시네이션 억제를 위해 자신이 짠 코드의 확신도(Confidence Score)를 %로 의무 선언하고, 50% 미만일 경우 코딩을 멈추고 인간에게 결정권을 넘기는 인식론적 겸손 명세서.

---

## 🚀 사용 방안 (How to Inject)

본 레포지토리를 클론(Clone)하여 `AI Agent(예: Cursor, Windsurf, Claude) 시스템 프롬프트`에 마운트(Mount) 하거나, 프로젝트의 `.agents/skills` 디렉토리에 **Git Submodule**로 삽입하십시오.

> [!WARNING] 
> **Context Overload (에이전트 과부하) 방지 요령**
> 12개 이상의 모든 `SKILL.md` 문서를 한 번의 프롬프트에 System Context로 전부 밀어 넣지 마십시오. 토큰 낭비와 'Lost in the middle(중간 지시어 망각)' 현상이 발생할 수 있습니다.
> 
> **"현재 작업하는 도메인에 필요한 스킬만 선별해서 동적으로 주입(RAG)해라"** 또는 **"수행할 명령어(Frontend, DB 등)에 따라 읽어야 할 `SKILL.md`를 먼저 필터링하라"**는 메타 프롬프트를 에이전트의 최상단 헌법에 작성해 두는 것이 완벽한 사용법입니다.

에이전트가 특정 스택(예: React/Next.js)을 수정하려 할 때, `typescript_core/SKILL.md` 문서를 최우선적으로 1회 정독하도록 컨텍스트를 주입(Provide context)하면 AI의 출력물(Output) 퀄리티가 주니어 레벨에서 시니어 아키텍트 레벨로 영원히 격상됩니다.
