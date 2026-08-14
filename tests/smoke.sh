#!/usr/bin/env sh
set -eu
image_ref="${IMAGE_REF:-deepseek-harness-docker:test}"

[ "$(docker image inspect --format '{{.Config.User}}' "$image_ref")" = "dsh" ]
docker image inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$image_ref" \
  | grep --fixed-strings --line-regexp 'DSH_HOME=/home/dsh/.dsh' >/dev/null
[ "$(docker image inspect --format '{{index .Config.Labels "org.opencontainers.image.licenses"}}' "$image_ref")" = "MIT" ]

container_id="$(docker run -d --rm -p 127.0.0.1:3080:3080 "$image_ref")"
trap 'docker rm -f "$container_id" >/dev/null 2>&1 || true' EXIT
for attempt in $(seq 1 30); do
  curl --fail --silent --show-error http://127.0.0.1:3080/ >/dev/null && exit 0
  sleep 1
done
docker logs "$container_id"
exit 1
