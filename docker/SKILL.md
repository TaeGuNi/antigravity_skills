---
name: Docker & Infrastructure Skill
description: >
  안전한 컨테이너 제어, 환경 변수 기반 Private Registry($DOCKER_REGISTRY_URL) 인증 및 사내망 환경에서의 인프라 접근을 규정하는 핵심 스킬.
---

# Antigravity용 Docker 및 인프라 운영 스킬

이 스킬 문서는 에이전트가 로컬 또는 원격 시스템에서 Docker 및 컨테이너 기반 인프라를 다룰 때 발생할 수 있는 치명적인 시스템 행오버(Hang-over)를 방지하고, 사용자님의 Private 인프라 규칙을 준수하기 위한 절대 원칙을 정의합니다.

## 1. 프라이빗 레지스트리 (Private Registry) 접근 규칙

환경 변수 `$DOCKER_REGISTRY_URL`를 통해 동적으로 주입된 대상 도커 레지스트리에 접근하여 이미지를 Pull 하거나 Push 할 때는 반드시 다음 에러 방어 흐름을 숙지하십시오.

1. **DNS 및 사내망 검증 (Network Pre-flight Check)**: 
   - 대상 레지스트리가 내부망 전용일 경우, 외부망에서는 DNS 쿼리가 실패합니다.
   - 접근 실패(`Cannot resolve host` 예외) 발생 시, 가장 먼저 VPN 연결 상태와 OS 레벨의 DNS 설정(예: `/etc/hosts` 또는 로컬 DNS 포워딩)을 점검해야 합니다. 섣불리 Docker 자체의 버그나 빌드 오류로 오판하지 마십시오.

2. **인증 유지 (Registry Login)**:
   - `unauthorized`, `access denied` 등의 권한 에러 발생 시, 엉뚱한 스크립트를 고치지 말고 가장 먼저 아래 명령어로 로그인 상태를 갱신해야 합니다.
   ```bash
   docker login $DOCKER_REGISTRY_URL
   ```

## 2. 에이전트의 컨테이너 제어 시 "절대 금지" 사항 (Anti-Hang Rules)

LLM 에이전트가 터미널 툴을 통해 Docker를 제어할 때 무심코 치는 명령어 하나가 전체 에이전트 프로세스를 영구적인 데드락(무한 대기)에 빠뜨릴 수 있습니다.

- **`-it` (인터랙티브 TTY) 옵션 사용 절대 금지**:
  에이전트에게는 키보드를 칠 수 있는 가상의 TTY가 주어지지 않습니다. `docker exec -it <container> bash`를 실행하는 순간, 에이전트는 무한 입력 대기 상태에 빠져 영원히 응답할 수 없게 됩니다.
  - ❌ 금지: `docker exec -it my_db psql ...`
  - ✅ 권장: `docker exec my_db psql ...` (TTY 없이 파이프로 넘기거나 백그라운드 실행)

- **로그 스트리밍 지속 금지 (`-f`)**:
  `docker logs -f` 명령어도 끝이 나지 않는 스트림이므로 에이전트의 컨텍스트를 터뜨립니다. 버그를 잡기 위해 로그를 볼 때는 반드시 꼬리 자르기(`--tail`)를 적용하십시오.
  - ❌ 금지: `docker logs -f my_app`
  - ✅ 권장: `docker logs --tail 200 my_app`

## 3. 리소스 누수 방지 및 디버깅 밸런스 (Garbage Collection & Observability)

에이전트가 단발성 테스트나 스크립트 실행을 위해 컨테이너를 올릴 때, 원칙적으로 디스크 공간 확보를 위해 `--rm` 옵션을 강제합니다. 하지만 컨테이너 내부의 치명적 에러 분석(Post-mortem)을 위한 "디버깅(Observability)"의 끈 마저 잘라버려서는 안 됩니다.

- **`--rm` 옵션의 양날의 검 원칙**:
  - ✅ **기본 원칙**: 데몬(`-d`)으로 띄우는 영구적인 서비스가 아닌 이상, 일회성 패키지 설치나 단순 조회(`docker run ubuntu cat /etc/os-release`) 등에는 무조건 `--rm` 옵션을 붙여 찌꺼기를 남기지 마십시오.
  - 🔍 **예외 (사후 검열/Observability 확보)**: 복잡한 코드 컴파일이나 크래시(Crash)율이 높은 실험적 환경을 테스트할 때는 **의도적으로 `--rm`을 제거**하십시오. 컨테이너가 죽은 뒤에도 내부 경로(`/tmp/error.log` 등)에 접속하거나 상세 로그를 뜯어보기 위한 고도의 전략적 판단입니다. 디버깅이 끝난 후에는 반드시 수동으로 `docker rm` 하여 정리하십시오.

## 4. 멀티 아키텍처 빌드 최적화 (Multi-Arch Buildx Protocol)

사용자님의 환경은 ARM(Apple Silicon)과 AMD(x86_64 원격 서버) 아키텍처가 혼재되어 작동하므로 `exec format error`라는 치명적인 런타임 에러를 방어해야 합니다. 하지만 모든 빌드마다 "에뮬레이션(QEMU)"을 태우는 것은 극심한 3~10배의 I/O 및 CPU 낭비(시간 지연)를 초래합니다.

- **`docker buildx` 속도 및 호환성 타협(Trade-off) 룰**:
  - 🔄 **로컬 전용 테스트 (초고속 빌드)**: 에이전트가 단지 현재 Mac 환경에서 구동 테스트만 해볼 목적이라면, 무조건 단일 아키텍처(ARM64) 빌드만 돌려 로컬 I/O를 극한으로 아끼십시오.
    ```bash
    # Test only
    docker build -t local-test-app .
    ```
  - 🚀 **레지스트리 릴리즈 (멀티 아키텍처 굽기)**: 로컬 검증이 완전히 끝나고 최종 배포판을 Private Registry에 Push 할 때만 `buildx` 플러그인을 사용하여 ARM64와 AMD64를 동시에 굽고(bake) 매니페스트를 통합하십시오.
    ```bash
    # Final Release push
    docker buildx create --use
    docker buildx build --platform linux/amd64,linux/arm64 -t $DOCKER_REGISTRY_URL/my-app:latest --push .
    ```

## 5. 컨테이너 내부 데이터 처리 전략

데이터베이스 컨테이너에 접근하여 데이터 마이그레이션이나 덤프를 수행할 때는, 텍스트 형태가 아닌 기계 친화적(Machine-readable)인 JSON 포맷으로 조작하여 컨텍스트 낭비를 최소화하십시오.
