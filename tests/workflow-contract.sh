#!/usr/bin/env sh
set -eu

workflow_dir=${WORKFLOW_DIR:-.github/workflows}

if [ ! -d "$workflow_dir" ]; then
  echo "workflow directory is missing: $workflow_dir" >&2
  exit 1
fi

workflow_files=$(find "$workflow_dir" -type f -name '*.yml' -o -type f -name '*.yaml')
if [ -z "$workflow_files" ]; then
  echo 'no workflow files found' >&2
  exit 1
fi

# Every uses: reference must be immutable and pinned to a full commit SHA.
if grep -nE '^[[:space:]]*uses:[[:space:]]*[^@]+@[^[:space:]#]+' $workflow_files |
  grep -vE '@[0-9a-fA-F]{40}([[:space:]#]|$)' >/dev/null; then
  echo 'all third-party actions must be pinned to a full 40-character commit SHA' >&2
  exit 1
fi

if [ -f "$workflow_dir/ci.yml" ] && grep -nE 'packages:[[:space:]]*write' "$workflow_dir/ci.yml" >/dev/null; then
  echo 'ci.yml must not grant packages: write' >&2
  exit 1
fi

ci="$workflow_dir/ci.yml"
publish="$workflow_dir/publish.yml"
upstream="$workflow_dir/check-upstream.yml"
for required in "$ci" "$publish" "$upstream"; do
  [ -f "$required" ] || { echo "missing workflow: $required" >&2; exit 1; }
done

grep -F 'pull_request:' "$ci" >/dev/null
grep -F 'branches: ["**"]' "$ci" >/dev/null
if grep -nE 'secrets\.|docker[[:space:]]+login|GITHUB_TOKEN' "$ci" >/dev/null; then
  echo 'ci.yml must not expose credentials or log in to a registry' >&2
  exit 1
fi

grep -F 'tags:' "$publish" >/dev/null
grep -F '"v*"' "$publish" >/dev/null
grep -F 'workflow_dispatch:' "$publish" >/dev/null
grep -F "github.ref == format('refs/heads/{0}', github.event.repository.default_branch)" "$publish" >/dev/null
grep -F 'packages: write' "$publish" >/dev/null
grep -F 'subject-digest: ${{ steps.image.outputs.digest }}' "$publish" >/dev/null

grep -F 'schedule:' "$upstream" >/dev/null
grep -F 'workflow_dispatch:' "$upstream" >/dev/null
if grep -nE 'build-push-action|docker[[:space:]]+push|docker[[:space:]]+buildx[[:space:]]+build.*--push' "$upstream" >/dev/null; then
  echo 'check-upstream.yml must not publish images' >&2
  exit 1
fi

# The workflow must use an ERE extraction that recognizes the literal Dockerfile pin.
grep -F "grep -Eo '@deepseek-ai/dsh@[0-9][^[:space:]\\\"]*' Dockerfile" "$upstream" >/dev/null
pinned="$(grep -Eo '@deepseek-ai/dsh@[0-9][^[:space:]\"]*' Dockerfile | sed 's/.*@//' | head -n 1)"
[ "$pinned" = '0.1.0-rc.6' ] || { echo "unexpected DSH pin: $pinned" >&2; exit 1; }
