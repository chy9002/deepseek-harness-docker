#!/usr/bin/env sh
set -eu

compose_file=docker-compose.yml
[ -f "$compose_file" ] || { echo "missing $compose_file" >&2; exit 1; }

grep --fixed-strings -- 'image: ghcr.io/chy9002/deepseek-harness:latest' "$compose_file" >/dev/null
grep --fixed-strings -- '127.0.0.1:3080:3080' "$compose_file" >/dev/null
grep --fixed-strings -- './data/dsh:/home/dsh/.dsh' "$compose_file" >/dev/null
grep --fixed-strings -- './workspace:/workspace' "$compose_file" >/dev/null
grep --fixed-strings -- 'restart: unless-stopped' "$compose_file" >/dev/null
grep --fixed-strings -- 'dsh-init:' "$compose_file" >/dev/null
grep --fixed-strings -- 'user: "0:0"' "$compose_file" >/dev/null
grep --fixed-strings -- 'chown -R dsh:dsh /home/dsh/.dsh /workspace' "$compose_file" >/dev/null
grep --fixed-strings -- 'condition: service_completed_successfully' "$compose_file" >/dev/null
