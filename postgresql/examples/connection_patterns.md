# PostgreSQL 연결 및 쿼리 실전 패턴

이 문서는 Antigravity `postgresql` 스킬을 사용하여 데이터베이스와 안전하게 통신하기 위한 레퍼런스 가이드입니다.

## 1. 환경 변수를 활용한 읽기 전용(Read-Only) 안전 조회

웹 애플리케이션의 `.env` 파일이 존재할 경우, 정보를 추출하여 파이썬 래퍼 스크립트에 넘겨줍니다. 이 방법은 극도로 안전하며, 별도의 타임아웃과 `READ ONLY` 트랜잭션 방벽이 기본 제공됩니다.

```bash
# 1. 환경 변수 소싱
export $(grep -v '^#' .env | xargs)

# 2. PG 표준 변수로 주입 (필요시)
export PGPASSWORD=$DB_PASSWORD
export PGUSER=$DB_USER
export PGDATABASE=$DB_NAME

# 3. 안전 조회 실행 (에러 핸들링 및 JSON 반환)
python3 skills/postgresql/scripts/safe_query.py "SELECT id, email, created_at FROM users ORDER BY created_at DESC LIMIT 5;"
```

## 2. Docker コンテナ (컨테이너) 기반 PostgreSQL 연결

데이터베이스가 Docker 내부에서만 돌고 포트가 외부로 빠져있지 않다면, SSH나 `docker exec`를 활용해야 합니다. 단독 쿼리가 아닌 스크립트를 전달할 때 유의하세요.

```bash
# 컨테이너 상태 확인
docker ps | grep postgres

# (주의) 직접 psql을 칠 경우 에이전트 보호 방벽(timeout, readonly, json 출력이)이 해제됩니다.
# 가급적 컨테이너 내부 쉘로 접속하여 쿼리 결과를 파일로 빼거나, URI를 활용하여 스크립트를 구동하십시오.
```

## 3. 스키마 안전 탐색 (정보 수집용)

새로운 테이블을 건드리기 전에는 **반드시** 스키마를 확인해야 합니다. 환각 상태로 존재하지 않는 컬럼을 참조하는 에러를 방지합니다.

```bash
# 1. 존재하는 기본 테이블 목록 수집
python3 skills/postgresql/scripts/schema_info.py list

# 2. 'products' 테이블의 구조 분석 (필드명, 타입, Nullable 확인)
python3 skills/postgresql/scripts/schema_info.py table products
```

## 4. 파괴적 데이터 수정 (The "Force Write" Pattern)

어느 데이터를 수정하거나 삭제해야 한다면, 단일문자열 안에 트랜잭션 블록(`BEGIN / COMMIT / ROLLBACK`)을 완전히 묶고 `--force-write` 플래그를 넘겨야만 합니다. psql이 하나의 세션으로 이를 모두 처리합니다.

```bash
# 1. 트랜잭션을 포함한 검증용 쿼리 스크립트 작성
cat << 'EOF' > update_target.sql
BEGIN;

-- 1.1) 수정
UPDATE users SET status = 'active' WHERE id = 123;

-- 1.2) 수정된 행이 맞는지 확인
SELECT id, status FROM users WHERE id = 123;

-- 1.3) 최종 결정 (에이전트 판단에 따라 COMMIT 혹은 ROLLBACK)
COMMIT;
EOF

# 2. 강제 끄기 허용 플래그와 함께 실행
python3 skills/postgresql/scripts/safe_query.py --force-write "$(<update_target.sql)"
```
