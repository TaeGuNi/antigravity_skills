---
name: MySQL Skill
description: >
  데이터 파괴를 방지하고, 에이전트의 컨텍스트를 보호하며, 직렬화된 JSON 출력을 통해 MySQL 데이터베이스와 안전하게 상호작용하기 위한 범용 핵심 스킬.
---

# Antigravity용 MySQL 스킬

이 스킬 문서는 에이전트가 MySQL 데이터베이스와 상호작용할 때 지켜야 할 운영 절차(SOP)와 헬퍼 스크립트 사용법을 정의합니다.

## 데이터베이스 스키마 설계 원칙 상속 (Inherited Schema Design Philosophy)

> [!IMPORTANT]
> MySQL 설계 및 아키텍처 판단 시 어떠한 예외 없이 **범용 RDBMS 아키텍처 스킬(`skills/rdbms_architecture/SKILL.md`)** 에 정의된 3대 절대 원칙(I/O 극대화, 플랫폼 불가지성, JSON 엄격 금지)과 세부 지침을 먼저 숙지하고 100% 준수해야 합니다.
> 아래의 헬퍼 스크립트를 실행하기 전, 설계 사상이 위배되지 않았는지 반드시 교차 검증하십시오.

## 5대 핵심 아키텍처 규칙 (Core Architecture Rules)

1. **기본 읽기 전용 모드 (Read-Only by Default)**:
   - 헬퍼 스크립트는 MySQL 세션에 접속 시 자동으로 `--readonly` 파라미터 또는 세션 레벨의 `SET SESSION TRANSACTION READ ONLY;` 를 주입하도록 설정되어야 합니다. (주의: MySQL의 경우 유저 권한에 따라 세션 레벨 제어가 다를 수 있으므로 DML 쿼리는 스크립트 레벨에서 차단 검증을 수행합니다).
   - 데이터를 변경(`INSERT`, `UPDATE`, `DELETE`, `DROP` 등)해야 하는 경우, 오직 `--force-write` 플래그를 명시적으로 선언했을 때만 허용됩니다.

2. **Stateless 트랜잭션 관리 원칙**:
   - 파이썬 헬퍼 스크립트는 매 호출마다 새로운 세션을 맺고 끊는 **Stateless(무상태)** 방식입니다. 터미널에 `START TRANSACTION;`을 던져놓고 다음 줄에서 `UPDATE`를 던지는 행위는 불가능합니다.
   - `--force-write` 시 쿼리를 파이프할 때 단일 문자열로 묶어서 전달하십시오.

3. **타임아웃 및 락 방지 (Timeout Enforcement)**:
   - MySQL 환경에서는 데드락 무한 대기를 방지하기 위해 `SET SESSION max_execution_time = 10000;` (10초) 설정값이 주입되어야 합니다 (지원되는 버전에 한함).

4. **리얼 JSON 출력 (Strict JSON Output)**:
   - 래퍼 스크립트는 `mysql -e` 의 TSV/텍스트 출력을 가로채서 순수한 **JSON 객체 배열** 문자열로 파싱해 반환합니다.
   - LLM 에이전트는 출력된 로그를 그대로 시스템 프롬프트 문맥으로 읽어 활용합니다.

5. **토큰 폭발 방지 (Context Economy)**:
   - `SELECT` 쿼리에는 필수적으로 `LIMIT N` (예: `LIMIT 10`)을 적용하십시오. 전체 테이블 덤프는 엄격히 금지합니다.

## 트러블슈팅

- **클라이언트 바이너리**: MySQL 명령어를 사용하려면 로컬(macOS)에 `mysql-client`가 설치되어 있어야 합니다. 없으면 에러가 납니다 (`brew install mysql-client`). PATH에 등록되어 있는지도 확인해야 합니다.
- **연결 확인**: 접속이 안 되는 경우 방화벽, 포트(보통 3306), 그리고 host가 `localhost`인지 `127.0.0.1`인지(소켓 접속 vs TCP 접속)에 주의하여 디버깅하십시오.

## 헬퍼 스크립트 (Helper Scripts)

### 1. `safe_query.py`

MySQL 쿼리를 JSON 배열로 변환하여 안전하게 반환합니다.

**경로**: `skills/mysql/scripts/safe_query.py`

**사용법 (조회 - 안전)**:

```bash
# 기본 사용 (환경 변수로 연결 정보 전달 권장)
export MYSQL_PWD="password"
python3 skills/mysql/scripts/safe_query.py -u root -h 127.0.0.1 -D mydb "SELECT id, email FROM users ORDER BY id DESC LIMIT 2;"
```

**사용법 (쓰기 - 위험, --force-write 사용)**:

```bash
cat << 'EOF' > update.sql
START TRANSACTION;
UPDATE users SET status = 'active' WHERE id = 1;
SELECT id, status FROM users WHERE id = 1;
COMMIT;
EOF

python3 skills/mysql/scripts/safe_query.py -u root -h 127.0.0.1 -D mydb --force-write "$(<update.sql)"
```
