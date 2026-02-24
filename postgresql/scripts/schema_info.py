#!/usr/bin/env python3
import argparse
import subprocess
import json
import csv
import sys
import os
import io

def run_psql_csv_command(cmd_args):
    """
    psql 명령을 실행하고 그 결과를 CSV 형식으로 받아 JSON 배열로 변환합니다.
    """
    cmd_args.append('--csv')
    try:
        result = subprocess.run(cmd_args, capture_output=True, text=True, check=True)
        raw_output = result.stdout.strip()
        
        if not raw_output:
            return "[]"
            
        # 결과가 일반 텍스트인 경우 처리
        if "\n" not in raw_output and "," not in raw_output and not raw_output.startswith("Schema,"):
            return json.dumps([{"status": raw_output}])
            
        csv_reader = csv.DictReader(io.StringIO(raw_output))
        if not csv_reader.fieldnames:
             return json.dumps([{"raw_output": raw_output}])
             
        rows = list(csv_reader)
        return json.dumps(rows, indent=2, ensure_ascii=False)

    except subprocess.CalledProcessError as e:
        print(f"Error executing psql command:", file=sys.stderr)
        print(e.stderr.strip(), file=sys.stderr)
        sys.exit(1)
    except FileNotFoundError:
        print("Error: 'psql' command not found. Please ensure PostgreSQL client tools are installed.", file=sys.stderr)
        sys.exit(1)

def get_tables(uri):
    """
    데이터베이스 내 사용자 생성 테이블 목록 조회 (\dt 와 유사한 자체 쿼리)
    뷰나 시스템 테이블이 아닌 기본 테이블만 가져옵니다.
    """
    query = """
    SELECT table_schema, table_name 
    FROM information_schema.tables 
    WHERE table_schema NOT IN ('information_schema', 'pg_catalog') 
    AND table_type = 'BASE TABLE';
    """
    cmd = ['psql']
    if uri:
        cmd.extend(['-d', uri])
    cmd.extend(['-c', query])
    return run_psql_csv_command(cmd)

def get_table_schema(table_name, uri):
    """
    특정 테이블의 상세 컬럼 및 데이터 타입 정보 반환 (\d 와 유사)
    """
    query = f"""
    SELECT column_name, data_type, character_maximum_length, column_default, is_nullable
    FROM information_schema.columns 
    WHERE table_name = '{table_name}';
    """
    cmd = ['psql']
    if uri:
        cmd.extend(['-d', uri])
    cmd.extend(['-c', query])
    return run_psql_csv_command(cmd)

def main():
    parser = argparse.ArgumentParser(description="PostgreSQL 스키마를 JSON 형식으로 빠르게 가져옵니다.")
    parser.add_argument('action', choices=['list', 'table'], help="수행할 액션: 'list'(테이블 목록), 'table'(특정 테이블 스키마)")
    parser.add_argument('table_name', nargs='?', help="'table' 액션 선택 시 필수인 테이블 이름")
    parser.add_argument('--uri', help="접속 주소 (예: postgresql://user:pass@host:port/db)", default=os.environ.get('PGURI'))

    args = parser.parse_args()

    if args.action == 'table' and not args.table_name:
        parser.error("The 'table' action requires a 'table_name' argument")

    if args.action == 'list':
        output = get_tables(args.uri)
    elif args.action == 'table':
        output = get_table_schema(args.table_name, args.uri)
        
    print(output)

if __name__ == "__main__":
    main()
