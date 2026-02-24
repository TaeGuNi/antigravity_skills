#!/usr/bin/env python3
import argparse
import subprocess
import json
import csv
import sys
import os
import io

def run_query(query, uri=None, force_write=False):
    """
    psql을 호출하여 쿼리를 실행한 뒤 결과를 JSON 배열 문자열로 반환합니다.
    """
    # 1. 아키텍처: 타임아웃 및 트랜잭션 안전성 주입
    # 모든 쿼리 시작 전에 강제 타임아웃 설정 설정 (10초)
    prefix_sql = "SET statement_timeout = '10000'; "
    if not force_write:
        # 강제 쓰기 플래그가 없으면 읽기 전용 세션 강제 (가장 강력한 방벽)
        prefix_sql += "SET SESSION CHARACTERISTICS AS TRANSACTION READ ONLY; "
    
    final_query = prefix_sql + query

    cmd = ['psql']
    if uri:
        cmd.extend(['-d', uri])
    
    cmd.extend([
        '-c', final_query,
        '--csv',          # 결과를 파싱하기 쉬운 CSV 포맷으로 요청
    ])

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        raw_output = result.stdout.strip()
        
        # psql --csv 출력은 테이블 결과가 없거나 단순 커밋 응답일 경우 일반 텍스트가 섞일 수 있음.
        # 출력 결과가 비어있다면 빈 배열 처리
        if not raw_output:
            return "[]"
            
        # 명령어 응답(예: "COMMIT" 또는 "UPDATE 1")인 경우 CSV 파서가 실패할 수 있음
        if "\n" not in raw_output and "," not in raw_output:
            return json.dumps([{"status": raw_output}])
            
        # CSV를 JSON 객체(Dictionary) 배열로 변환
        csv_reader = csv.DictReader(io.StringIO(raw_output))
        # 필드명이 없는 찌꺼기 텍스트 방어
        if not csv_reader.fieldnames:
             return json.dumps([{"raw_output": raw_output}])
             
        rows = list(csv_reader)
        return json.dumps(rows, indent=2, ensure_ascii=False)

    except subprocess.CalledProcessError as e:
        print(f"Error executing query:", file=sys.stderr)
        print(e.stderr.strip(), file=sys.stderr)
        sys.exit(1)
    except FileNotFoundError:
        print("Error: 'psql' command not found. Please ensure PostgreSQL client tools are installed.", file=sys.stderr)
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="PostgreSQL 쿼리를 안전하게 실행하고 JSON으로 결과를 반환합니다.")
    parser.add_argument('query', help="실행할 SQL 쿼리 문자열")
    parser.add_argument('--uri', help="접속 주소 (예: postgresql://user:pass@host:port/db)", default=os.environ.get('PGURI'))
    parser.add_argument('--force-write', action='store_true', help="기본 Read-Only 방벽을 우회하고 DML/DDL 쓰기 모드를 허용합니다.")
    
    args = parser.parse_args()
    
    # 기초적인 휴먼 에러 방지 (Stateless 트랜잭션 경고)
    upper_query = args.query.upper()
    destructive_keywords = ['DROP', 'TRUNCATE', 'ALTER', 'DELETE', 'UPDATE', 'INSERT']
    
    has_destructive = any(keyword in upper_query for keyword in destructive_keywords)
    
    if args.force_write and has_destructive:
        if 'BEGIN' not in upper_query and 'COMMIT' not in upper_query and 'ROLLBACK' not in upper_query:
            print("[경고] --force-write가 켜져 있으나 단일 쿼리 문자열 내에 명시적인 트랜잭션 블록(BEGIN; ... COMMIT;)이 존재하지 않습니다.", file=sys.stderr)
            print("[경고] 이는 의도치 않은 파괴적 자동 커밋(Auto-Commit)을 유발할 수 있습니다. 극도로 주의하십시오.\n", file=sys.stderr)

    if not args.force_write and has_destructive:
         print("[정보] 파괴적 쿼리 키워드가 감지되었으나 --force-write 플래그가 없습니다. 예외가 발생할 것입니다.", file=sys.stderr)
             
    output = run_query(args.query, args.uri, args.force_write)
    print(output)

if __name__ == "__main__":
    main()
