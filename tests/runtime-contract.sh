#!/usr/bin/env sh
set -eu

dockerfile=$(sed ':a;N;$!ba;s/\\\n/ /g' Dockerfile)
case "$dockerfile" in
  *'ARG DSH_VERSION'*) echo 'DSH version must not be build-arg overridable' >&2; exit 1 ;;
esac
printf '%s\n' "$dockerfile" | grep -F 'npm install --global --omit=dev @deepseek-ai/dsh@0.1.0-rc.6' >/dev/null

grep -F 'kill "$dsh_pid"' docker/entrypoint.sh >/dev/null
grep -F 'wait "$dsh_pid"' docker/entrypoint.sh >/dev/null
grep -F 'kill "$proxy_pid"' docker/entrypoint.sh >/dev/null
grep -F 'wait "$proxy_pid"' docker/entrypoint.sh >/dev/null
grep -F "trap 'forward_signal' INT TERM" docker/entrypoint.sh >/dev/null
grep -F 'trap cleanup EXIT' docker/entrypoint.sh >/dev/null
