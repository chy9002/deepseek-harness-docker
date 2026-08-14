#!/usr/bin/env sh
set -eu

dsh web --port 3081 &
dsh_pid=$!

socat TCP-LISTEN:3080,bind=0.0.0.0,reuseaddr,fork TCP:127.0.0.1:3081 &
proxy_pid=$!

forward_signal() {
  kill "$dsh_pid" 2>/dev/null || true
  kill "$proxy_pid" 2>/dev/null || true
}

cleanup() {
  kill "$proxy_pid" 2>/dev/null || true
  wait "$proxy_pid" 2>/dev/null || true
  kill "$dsh_pid" 2>/dev/null || true
  wait "$dsh_pid" 2>/dev/null || true
}
trap 'forward_signal' INT TERM
trap cleanup EXIT

set +e
wait "$dsh_pid"
dsh_status=$?
set -e
exit "$dsh_status"
