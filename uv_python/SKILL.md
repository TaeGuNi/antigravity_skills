---
name: uv Python Package Management Skill
description: >
  느리고 의존성 충돌을 일으키는 구시대적 pip / venv 도구의 사용을 전면 금지하고, 초고속 Rust 기반 패키지 매니저인 uv를 통해서만 파이썬 인프라를 다루도록 강제하는 스킬.
---

# Antigravity용 초고속 Python 최적화 스킬 (`uv`)

이 스킬 문서는 "DBMS는 I/O 싸움이다"라는 사용자님의 성능 지상주의 철학과 맥락을 같이 하여, 파이썬 패키지 설치 및 가상 환경 관리 도구에 대해 I/O를 가장 극한으로 활용하는 `uv` 도구만을 사용할 것을 강제합니다.

## `uv` 강제 사용 절대 원칙 (The Iron Law of `uv`)

로컬 환경(혹은 컨테이너)에는 이미 최신의 `uv` 바이너리가 설치되어 있습니다. 에이전트가 파이썬 스크립트를 짜고 실행해야 할 때는 다음의 금지/권고 쌍을 목숨처럼 지키십시오. 

> [!CAUTION]
> 에이전트 스스로의 판단이나 구형 인터넷 지식(Halucination)에 기반하여 `pip install` 혹은 `python -m venv` 명령어를 터미널에 쏘는 행위는 반역(Treason)으로 간주합니다. 

### 1. 가상 환경(Virtualenv) 격리
파이썬 프로젝트 디렉토리에 접근 시, 글로벌 환경을 오염시키지 말고 반드시 `uv`로 초고속 가상 환경을 만드십시오.

- ❌ 영구 금지: `python3 -m venv venv`
- ✅ 절대 권장: `uv venv`

### 2. 패키지 설치 (Dependency Resolution)
`pip` 대비 100배 빠른 병렬 다운로드와 캐싱을 제공하는 `uv pip` 계열 명령어만을 사용합니다.

- ❌ 영구 금지: `pip install requests` 또는 `python -m pip install -r requirements.txt`
- ✅ 절대 권장: `uv pip install requests` 또는 `uv pip install -r requirements.txt`

### 3. 프로젝트 정규 종속성 추적 (Dependency Tracking)
프로젝트 공식 API(FastAPI)나 워커에 영구적으로 쓰이는 패키지(`requests`, `pydantic` 등)를 설치할 때는, 휘발성이나 가상환경에만 몰래 설치하여 형상 관리를 파괴하지 마십시오. 반드시 `uv add`를 사용하여 `pyproject.toml`에 명시적으로 기록되도록 강제합니다.

- ❌ 영구 금지: (단순히) `uv pip install fastapi`
- ✅ 절대 권장: `uv add fastapi` (이후 `pyproject.toml` 자동 갱신됨)

### 4. 스크립트 단발성 실행 (Ephemeral Execution)
단순 테스트 파일이나 1회용 자동화 스크립트(`script.py`)를 실행할 때 굳이 환경을 세팅하지 마십시오. `uv run`을 사용하면 런타임에 필요한 패키지만 휘발성으로 묶어 눈 깜짝할 새에 코드를 실행합니다.

- ❌ 영구 금지: `source venv/bin/activate && pip install x && python script.py`
- ✅ 절대 권장: `uv run --with "requests" script.py`

## 도입 효과 (I/O 극대화)
이 가이드라인을 지킴으로써 에이전트의 터미널 명령어 대기/실행 시간은 밀리초(ms) 단위로 폭주하며 시스템의 전반적인 응답성과 패키지 무결성 보호 수준이 한 차원 승격됩니다.
