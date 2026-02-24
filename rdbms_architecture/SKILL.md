---
name: RDBMS Architecture & Schema Design
description: >
  PostgreSQL, MySQL, MariaDB 등 모든 관계형 데이터베이스(RDBMS)를 다룰 때 에이전트가 공통적으로 최우선 준수해야 하는 스키마 설계 헌법이자 3대 절대 원칙.
---

# Antigravity용 범용 RDBMS 아키텍처 스킬 (Abstract Core)

이 스킬 문서는 특정 DBMS(PostgreSQL, MySQL 등)의 터미널 조작법을 다루지 않습니다. 대신, 에이전트가 주도적으로 테이블을 생성하거나 쿼리를 논리적으로 설계할 때 핑계나 타협 없이 지켜야 하는 **"RDBMS의 뼈대(Pillars)"**를 정의합니다. 특정 DB 스킬을 사용하기 전, 설계 및 아키텍처 판단이 필요할 때 반드시 이 문서를 먼저 숙지하고 상속(Inherit)받으십시오.

## 데이터베이스 스키마 설계 3대 절대 원칙 (Immutable Schema Design Philosophy)

1. **타입 최소화 기반의 I/O 극대화 (Strict Data Type Compression)**:
   - 데이터베이스 성능의 본질은 I/O 싸움입니다. 메모리 버퍼 적중률과 디스크 I/O 최적화를 위해 무조건 가장 작고 고정된 데이터 타입을 선택하십시오.
   - 무분별한 `BIGINT`, `TEXT` 남용이나 넉넉한 자원 할당을 **절대 금지**합니다. 값의 범위가 명확하다면 `SMALLINT`, `INTEGER`, 또는 `BOOLEAN`을 강제하십시오.

2. **플랫폼 불가지성 유지 지향 (Strict ANSI SQL & Agnosticism)**:
   - 특정 DBMS에 지나치게 종속적인 비표준 문법(Vendor-specific features) 사용을 **엄격히 제한**합니다. 
   - 언제든 다른 RDBMS로 이주(Migration)할 수 있는 아키텍처 유연성을 보장하기 위해, 어플리케이션 계층이나 ORM이 해석할 수 있는 범용적인 **ANSI 표준 SQL** 레벨에서 엔티티와 비즈니스 로직을 구축하십시오.

3. **JSON 연산 및 조인 엄격히 금지 (RDBMS Purism)**:
   - RDBMS는 Document DB가 아닙니다. JSON/JSONB 타입은 어플리케이션 단에서 꺼내 쓰기 위한 '단순 저장소(Payload)' 용도로만 제한적으로 허용됩니다.
   - 데이터베이스 내부에서 JSON 필드를 언래핑하여 활용하는 검색 조건(`WHERE data->>...`), 조인(JOIN) 연산은 인덱싱과 실행 계획을 파괴하므로 **어떠한 예외도 없이 엄격히 금지**합니다. 
   - 개발 코스트가 상승하더라도, EAV(Entity-Attribute-Value) 모델을 고도화하거나 데이터 도메인을 정확히 식별하여 테이블을 쪼개는(정규화하는) 정공법이 수억 건의 트래픽을 맞이했을 때 시스템이 죽지 않고 버티게 해주는 유일한 길입니다. 복잡한 쿼리가 필요한 데이터는 **반드시 일반 컬럼으로 정규화(Normalization)**하여 해결하십시오.

---

### 세부 설계 지침 (Detailed Guidelines)

1. **B-Tree 인덱스 친화적 설계 (B-Tree Optimization)**:
   - **기본 키(PK)**: 완전 무작위인 UUID v4를 PK로 사용하는 것을 금지합니다. 이는 B-Tree 인덱스의 단편화(Fragmentation)를 유발하고 `INSERT` 성능을 파괴합니다. 연속성이 보장되는 정수형 자동 증가(예: `BIGSERIAL`, `AUTO_INCREMENT`) 시퀀스나, 순차적으로 발급되는 UUID v7 패턴을 사용하십시오.
   - **복합 인덱스(Composite Index)**: B-Tree의 카디널리티(Cardinality, 선택도)를 고려하여, 쿼리의 좌측 선행(Left-most) 조건으로 항상 쓰이면서 분포도가 높은 컬럼을 인덱스의 앞쪽에 배치하십시오.

2. **외래 키(FK)를 통한 무결성 확보 및 분산 환경 대비 (Integrity & Extensibility)**:
   - **FK 설계**: 어플리케이션 레벨의 로직에만 의존하지 말고, 데이터 무결성 보장을 위해 기본적으로 외래 키(Foreign Key) 제약 조건을 사용하여 스키마를 설계하십시오.
   - **Trade-off 자각**: 단, 초당 수천 건의 트랜잭션이 발생하는 대용량 테이블이거나, 향후 마이크로서비스(MSA) 및 데이터베이스 분리(Sharding)가 예정된 도메인 경계에서는 물리적 FK가 병목(Lock/Coupling)이 될 수 있습니다. 이 경우 논리적 제약(Logical Integrity)만 유지하고 물리적 제약은 해제하는 유연성을 발휘하십시오.
   - **ENUM 대체**: `ENUM` 타입은 향후 값이 추가, 수정되거나 확장될 때 DDL 조각화 등 유지보수의 어려움이 따릅니다. 따라서 상태(Status)나 분류(Type) 값은 `ENUM` 타입 대신 작고 분리된 '코드 매핑 테이블'을 명시적으로 생성하고 외래 키(FK)로 연결하여 구성하십시오.

3. **ORM 및 쿼리 최적화 가이드라인 (ORM & Query Optimization)**:
   - 개발 생산성을 위해 ORM(Prisma, TypeORM, SQLAlchemy 등) 사용을 기본적으로 허용합니다.
   - 단, N+1 문제나 비효율적인 다중 서브쿼리를 유발하는 맹목적인 ORM 체이닝은 엄격히 지양합니다. 복잡한 집계(Aggregation)나 대량의 DML 연산 시에는 ORM의 Raw Query 기능을 사용하거나, 가벼운 Query Builder(예: Kysely, Knex)를 활용하여 최적화된 ANSI SQL을 직접 제어하십시오.
   - **Prepared Statement 필수 사용**: 보안(SQL Injection 방지)과 성능(Query Plan 캐싱)을 위해, 어플리케이션에서 파라미터가 바인딩되는 모든 동적 쿼리는 반드시 Prepared Statement를 거치도록 구현하십시오. 클라이언트 사이드 문자열 포매팅(String interpolation)으로 쿼리를 조립하는 것은 범죄에 가깝습니다.
   - **커넥션 풀(Connection Pool) 적극 활용**: RDBMS의 연결 비용(Handshake, Auth)은 매우 비쌉니다. 어플리케이션 레벨(예: PgBouncer, HikariCP, Prisma Accelerate 등)에서 적절한 크기의 Connection Pool을 구성하여 재사용성을 극대화하십시오. 단, Pool Size를 과도하게 늘리면 데이터베이스의 Memory와 CPU 컨텍스트 스위칭 오버헤드로 인해 오히려 성능이 저하되므로(Max Connections 고갈), 코어 수와 디스크 성능을 고려하여 보수적으로 설정(예: `(CPU Core * 2) + 1`)하는 것을 원칙으로 합니다.
   - 데이터베이스 스키마 마이그레이션 파일은 데이터베이스 불가지성(Agnosticism)을 해치지 않도록, 특정 DBMS에 종속적인 확장을 남용하지 않는 선에서 작성되어야 합니다.
