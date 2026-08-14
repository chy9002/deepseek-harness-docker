#!/usr/bin/env sh
set -eu

dockerfile=$(sed ':a;N;$!ba;s/\\\n/ /g' Dockerfile)
case "$dockerfile" in
  *'ARG DSH_VERSION'*) echo 'DSH version must not be build-arg overridable' >&2; exit 1 ;;
esac
printf '%s\n' "$dockerfile" | grep -F 'npm install --global --omit=dev @deepseek-ai/dsh@0.1.0-rc.6' >/dev/null
printf '%s\n' "$dockerfile" | grep -F 'apt-get install --no-install-recommends --yes tini socat curl python3 make g++' >/dev/null
grep -Fx 'dsh web --port 3081 &' docker/entrypoint.sh >/dev/null
grep -Fx 'socat TCP-LISTEN:3080,bind=0.0.0.0,reuseaddr,fork TCP:127.0.0.1:3081 &' docker/entrypoint.sh >/dev/null
if grep -F 'docker run -d --rm' tests/smoke.sh >/dev/null; then
  echo 'smoke test must retain failed containers long enough to print diagnostics' >&2
  exit 1
fi
grep -F 'docker inspect --format' tests/smoke.sh >/dev/null

grep -F 'kill "$dsh_pid"' docker/entrypoint.sh >/dev/null
grep -F 'wait "$dsh_pid"' docker/entrypoint.sh >/dev/null
grep -F 'kill "$proxy_pid"' docker/entrypoint.sh >/dev/null
grep -F 'wait "$proxy_pid"' docker/entrypoint.sh >/dev/null
grep -F "trap 'forward_signal' INT TERM" docker/entrypoint.sh >/dev/null
grep -F 'trap cleanup EXIT' docker/entrypoint.sh >/dev/null
