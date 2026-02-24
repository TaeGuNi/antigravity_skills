---
name: PostgreSQL Skill
description: >
  데이터 파괴를 방지하고, 에이전트의 컨텍스트를 보호하며, 직렬화된 JSON 출력을 통해 PostgreSQL 데이터베이스와 안전하게 상호작용하기 위한 범용 핵심 스킬.
---

# Antigravity용 PostgreSQL 스킬

이 스킬 문서는 에이전트가 PostgreSQL 데이터베이스와 상호작용할 때 반드시 지켜야 할 표준 운영 절차(SOP)와 5대 핵심 아키텍처 규칙을 정의합니다.

## 5대 핵심 아키텍처 규칙 (Core Architecture Rules)

1. **기본 읽기 전용 모드 (Read-Only by Default)**:
   - 모든 쿼리는 기본적으로 `READ ONLY` 트랜잭션으로 실행됩니다.
   - 데이터를 변경(`INSERT`, `UPDATE`, `DELETE`, `DROP` 등)해야 하는 경우, 오직 `--force-write` 플래그를 명시적으로 선언했을 때만 허용됩니다.

2. **Stateless 트랜잭션 관리 원칙**:
   - 파이썬 헬퍼 스크립트는 매 호출마다 새로운 세션을 맺고 끊는 **Stateless(무상태)** 방식입니다.
   - 터미널에 `BEGIN;`을 먼저 날리고 다음 명령어에서 `UPDATE`를 날리는 방식은 **절대 동작하지 않습니다** (자동 커밋되어 버림).
   - 변경 작업을 수행하려면 `--force-write` 플래그를 사용하고, 반드시 단일 문자열 안에 `BEGIN; UPDATE ...; SELECT ...; ROLLBACK;` (검증용) 또는 `BEGIN; UPDATE ...; COMMIT;` 블록을 통째로 파이프해야 합니다.

3. **타임아웃 및 락 방지 (Timeout Enforcement)**:
   - 에이전트가 무한 루프나 데드락에 빠지는 것을 막기 위해 헬퍼 스크립트는 모든 세션에 대해 `SET statement_timeout = '10000';` (10초) 설정값을 자동으로 주입합니다.

4. **리얼 JSON 출력 (Strict JSON Output)**:
   - 래퍼 스크립트는 `psql`의 CSV 출력을 가로채서 순수한 **JSON 객체 배열** 문자열로 변환하여 출력합니다.
   - LLM 에이전트는 출력된 로그를 그대로 시스템 프롬프트 문맥으로 읽거나 파이썬의 `json.loads()`로 즉시 파싱하여 자유롭게 활용할 수 있습니다.

5. **토큰 폭발 방지 (Context Economy)**:
   - `SELECT` 쿼리에는 필수적으로 `LIMIT N` (예: `LIMIT 10`)을 적용하십시오. 전체 테이블 내용을 한 번에 메모리에 덤프하는 행위를 엄격히 금지합니다.

## 데이터베이스 스키마 설계 원칙 상속 (Inherited Schema Design Philosophy)

> [!IMPORTANT]
> PostgreSQL 역시 관계형 데이터베이스이므로, 스키마 설계 및 아키텍처 판단 시 어떠한 예외 없이 **범용 RDBMS 아키텍처 스킬(`skills/rdbms_architecture/SKILL.md`)** 에 정의된 3대 절대 원칙(I/O 극대화, 플랫폼 불가지성, JSON 엄격 금지)과 세부 지침을 먼저 숙지하고 100% 준수해야 합니다.
> 아래의 헬퍼 스크립트를 실행하기 전, 설계 사상이 위배되지 않았는지 반드시 교차 검증하십시오.

## 트러블슈팅 및 클라우드 DB 연결 (Troubleshooting & SSL)

- **클라우드 연결 (RDS, Supabase 등)**: SSL 인증이 필수인 환경이라면 환경 변수 `PGSSLMODE=require`를 추가로 설정하십시오.
- **연결 확인**: 접속이 안 되는 경우 막연히 비밀번호 오류라고 추측하지 마십시오. 먼저 `pg_isready -h <host> -p <port>` 및 `nc -vz <host> <port>` 명령어를 통해 네트워크 방화벽 문제인지 인증 문제인지 식별하십시오.

## 헬퍼 스크립트 (Helper Scripts)

### 1. `safe_query.py`

PostgreSQL 쿼리를 JSON 배열로 변환하여 안전하게 반환합니다. 기본적으로 타임아웃 10초 및 읽기 전용(`READ ONLY`)이 강제됩니다.

**경로**: `skills/postgresql/scripts/safe_query.py`

**사용법 (조회 - 안전)**:

```bash
# 기본 사용 (READ ONLY 적용)
export PGURI="postgresql://postgres:secret@localhost:5432/mydb"
python3 skills/postgresql/scripts/safe_query.py "SELECT id, email FROM users ORDER BY id DESC LIMIT 2;"
# 출력: [{"id": "2", "email": "test2@test.com"}, {"id": "1", "email": "test1@test.com"}]
```

**사용법 (쓰기 - 위험, --force-write 사용)**:

```bash
# 단일 트랜잭션 블록 내에서 모두 처리해야 함
cat << 'EOF' > update_query.sql
BEGIN;
UPDATE users SET status = 'active' WHERE id = 1;
SELECT id, status FROM users WHERE id = 1;
COMMIT;
EOF

python3 skills/postgresql/scripts/safe_query.py --force-write "$(<update_query.sql)"
```

### 2. `schema_info.py`

특정 테이블의 메타데이터(컬럼 명, 타입 등) 및 테이블 목록을 JSON 형식과 유사하게 깔끔히 정제하여 가져옵니다. 쿼리 작성 전 구조 파악용으로 필수입니다.

**경로**: `skills/postgresql/scripts/schema_info.py`

**사용법**:

```bash
# 전체 테이블 목록 확인
python3 skills/postgresql/scripts/schema_info.py list

# 'orders' 테이블 상세 스키마 확인
python3 skills/postgresql/scripts/schema_info.py table orders
```
