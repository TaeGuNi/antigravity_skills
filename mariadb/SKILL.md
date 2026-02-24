---
name: MariaDB Skill
description: >
  데이터 파괴를 방지하고, 에이전트의 컨텍스트를 보호하며, 직렬화된 JSON 출력을 통해 MariaDB 데이터베이스와 안전하게 상호작용하기 위한 범용 핵심 스킬.
---

# Antigravity용 MariaDB 스킬

이 스킬 문서는 에이전트가 MariaDB 데이터베이스와 상호작용할 때 지켜야 할 운영 절차(SOP)와 헬퍼 스크립트 사용법을 정의합니다.

## 데이터베이스 스키마 설계 원칙 상속 (Inherited Schema Design Philosophy)

> [!IMPORTANT]
> MariaDB 설계 및 아키텍처 판단 시 어떠한 예외 없이 **범용 RDBMS 아키텍처 스킬(`skills/rdbms_architecture/SKILL.md`)** 에 정의된 3대 절대 원칙(I/O 극대화, 플랫폼 불가지성, JSON 엄격 금지)과 세부 지침을 먼저 숙지하고 100% 준수해야 합니다.
> 아래의 헬퍼 스크립트를 실행하기 전, 설계 사상이 위배되지 않았는지 반드시 교차 검증하십시오.

## 5대 핵심 아키텍처 규칙 (Core Architecture Rules)

1. **기본 읽기 전용 모드 (Read-Only by Default)**:
   - 본 스킬은 데이터를 변경(`INSERT`, `UPDATE`, `DELETE`, `DROP` 등)해야 하는 경우, 오직 `--force-write` 플래그를 명시적으로 선언했을 때만 허용됩니다. 스크립트 레벨에서 파괴적 키워드를 감시하고 차단합니다.

2. **Stateless 트랜잭션 관리 원칙**:
   - 파이썬 헬퍼 스크립트는 매 호출마다 새로운 세션을 맺고 끊는 **Stateless(무상태)** 방식입니다.
   - 단일 트랜잭션을 묶으려면 반드시 `$()` 서브쉘이나 파일 파이프를 통해 `START TRANSACTION; ... COMMIT;` 블록을 통째로 전달해야 합니다.

3. **타임아웃 및 락 방지 (Timeout Enforcement)**:
   - MariaDB 환경에서는 무한 대기를 방지하기 위해 쿼리 전 `SET STATEMENT max_statement_time = 10 FOR {query}` 와 같은 타임아웃 주입이 권장됩니다 (스크립트 내장).

4. **리얼 JSON 출력 (Strict JSON Output)**:
   - 래퍼 스크립트는 `mysql -e` (MariaDB 클라이언트 대체 호환)의 출력을 가로채서 순수한 **JSON 객체 배열** 문자열로 파싱해 반환합니다.

5. **토큰 폭발 방지 (Context Economy)**:
   - `SELECT` 쿼리에는 필수적으로 `LIMIT N` (예: `LIMIT 10`)을 적용하십시오. 전체 테이블 덤프는 엄격히 금지합니다.

## 트러블슈팅

- **클라이언트 바이너리**: MariaDB 접속 시에도 macOS 로컬에 설치된 범용 `mysql-client` 바이너리(`brew install mysql-client`)를 그대로 사용합니다. 만약 명령어를 찾을 수 없다고 나오면 PATH 설정을 디버깅하십시오.

## 헬퍼 스크립트 (Helper Scripts)

### 1. `safe_query.py`

MariaDB 쿼리를 JSON 배열로 변환하여 안전하게 반환합니다. (내부적으로 mysql 클라이언트를 래핑합니다).

**경로**: `skills/mariadb/scripts/safe_query.py`

**사용법 (조회 - 안전)**:

```bash
# 기본 사용 
python3 skills/mariadb/scripts/safe_query.py -u root -h 127.0.0.1 -D mydb "SELECT id, email FROM users ORDER BY id DESC LIMIT 2;"
```

**사용법 (쓰기 - 위험, --force-write 사용)**:

```bash
cat << 'EOF' > update_maria.sql
START TRANSACTION;
UPDATE users SET status = 'active' WHERE id = 1;
SELECT id, status FROM users WHERE id = 1;
COMMIT;
EOF

python3 skills/mariadb/scripts/safe_query.py -u root -h 127.0.0.1 -D mydb --force-write "$(<update_maria.sql)"
```
