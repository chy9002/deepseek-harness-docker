#!/usr/bin/env sh
set -eu

compose_file=${COMPOSE_FILE:-compose.yaml}
dockerfile=${DOCKERFILE:-Dockerfile}

grep --fixed-strings -- '127.0.0.1:3080:3080' "$compose_file" >/dev/null
grep --fixed-strings -- 'dsh-state:/home/dsh/.dsh' "$compose_file" >/dev/null
grep --fixed-strings -- './workspace:/workspace' "$compose_file" >/dev/null
grep --fixed-strings -- 'USER dsh' "$dockerfile" >/dev/null
grep --fixed-strings -- 'ENV DSH_HOME=/home/dsh/.dsh' "$dockerfile" >/dev/null
grep --fixed-strings -- 'org.opencontainers.image.licenses="MIT"' "$dockerfile" >/dev/null

if grep --fixed-strings --quiet -- 'API_KEY=' "$compose_file" "$dockerfile"; then
  echo 'credentials must not be committed to image or Compose configuration' >&2
  exit 1
fi
