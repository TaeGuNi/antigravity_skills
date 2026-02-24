#!/usr/bin/env python3
import sys
import argparse
import subprocess
import json
import re

def main():
    parser = argparse.ArgumentParser(description="A safe wrapper for executing MariaDB queries returning JSON.")
    parser.add_argument("query", help="The raw SQL query to execute")
    parser.add_argument("--force-write", action="store_true", help="Allow destructive DML/DDL queries (INSERT, UPDATE, DELETE, DROP, ALTER)")
    parser.add_argument("-u", "--user", default="root", help="MariaDB user")
    parser.add_argument("-h", "--host", default="127.0.0.1", help="MariaDB host")
    parser.add_argument("-P", "--port", default="3306", help="MariaDB port")
    parser.add_argument("-D", "--database", default="", help="MariaDB database name")
    
    args = parser.parse_args()
    
    query = args.query.strip()
    is_destructive = re.search(r'\b(insert|update|delete|drop|alter|truncate|replace|grant|revoke)\b', query, re.IGNORECASE)
    
    if is_destructive and not args.force_write:
        print(json.dumps({
            "error": "Destructive query detected (INSERT, UPDATE, DELETE, DROP, ALTER, etc). You must explicitly provide the --force-write flag to execute this query. This is a safety mechanism.",
            "query": query
        }), file=sys.stderr)
        sys.exit(1)
        
    cmd = [
        "mysql",  # MariaDB is compatible with the mysql client binary
        "-u", args.user,
        "-h", args.host,
        "-P", args.port,
        "-B", # Batch mode (returns tab separated)
        "-e"
    ]
    if args.database:
        cmd.extend(["-D", args.database])
        
    # Inject timeout context. MariaDB uses max_statement_time (seconds).
    # MySQL uses max_execution_time (milliseconds). Because we don't strictly know if it's Maria or MySQL yet (both use the mysql bin),
    # we just run the query. To be super safe natively for mariadb without failing on parse:
    safe_query_block = ""
    if not args.force_write:
        safe_query_block = f"SET SESSION max_statement_time = 10; {query}"
    else:
        safe_query_block = query

    cmd.append(safe_query_block)
    
    try:
        # Run mysql client
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=False 
        )
        
        # Fallback if max_statement_time fails because it's actually connected to MySQL server not MariaDB.
        if "Unknown system variable 'max_statement_time'" in result.stderr:
            cmd[-1] = query # run without the variable
            result = subprocess.run(cmd, capture_output=True, text=True, check=False)

        if result.returncode != 0:
            print(json.dumps({
                "error": "MariaDB cli failed",
                "stderr": result.stderr.strip()
            }))
            sys.exit(1)
            
        output = result.stdout.strip()
        if not output:
            print(json.dumps({"result": "Success(No output or rows affected)"}))
            sys.exit(0)
            
        # Parse TSV output from mysql -B
        lines = output.split('\n')
        if not lines:
            print(json.dumps({"result": "Empty"}))
            sys.exit(0)
            
        headers = lines[0].split('\t')
        json_result = []
        for line in lines[1:]:
            values = line.split('\t')
            row = dict(zip(headers, values))
            json_result.append(row)
            
        print(json.dumps(json_result, ensure_ascii=False, indent=2))
        
    except Exception as e:
        print(json.dumps({"error": str(e)}), file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
