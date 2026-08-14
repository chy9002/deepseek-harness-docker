# DeepSeek Harness Docker Image Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build, test, and publish a secure-by-default `@deepseek-ai/dsh` Docker image to GHCR.

**Architecture:** Install a pinned npm release of DSH into a Node 22 Debian-slim image. Keep DSH bound to loopback and proxy the container port through `socat`; test the image with a shell smoke test. GitHub Actions validates pull requests and publishes only trusted tagged/manual releases.

**Tech Stack:** Docker, Docker Compose, POSIX shell, Node.js 22, GitHub Actions, GHCR.

## Global Constraints

- Pin `@deepseek-ai/dsh` to an exact version; never install `latest` or use unbounded `npx`.
- Run the final image as non-root and set `DSH_HOME=/home/dsh/.dsh`.
- Expose port `3080`, but Compose must bind it to `127.0.0.1` by default.
- Never add API keys, `.env` files, or credentials to image layers, repository files, or workflow logs.
- Pin every third-party GitHub Action to a full commit SHA.
- PR workflows build and test only; publication is allowed only from version tags or manual dispatch on the default branch.

---

## File Structure

- `Dockerfile`: pinned DSH runtime image and OCI labels.
- `docker/entrypoint.sh`: starts DSH and loopback-to-container-port proxy.
- `compose.yaml`: safe local development/run example with named state volume.
- `tests/smoke.sh`: image assertions and HTTP startup smoke test.
- `.github/workflows/ci.yml`: pull-request and branch build/test workflow.
- `.github/workflows/publish.yml`: trusted GHCR publish + attestation workflow.
- `.github/workflows/check-upstream.yml`: scheduled npm-version check that opens an issue only.
- `README.md`: run instructions, persistence, security boundaries, and release usage.

### Task 1: Container runtime and smoke test

**Files:**
- Create: `tests/smoke.sh`
- Create: `Dockerfile`
- Create: `docker/entrypoint.sh`
- Create: `.dockerignore`

**Interfaces:**
- Consumes: `IMAGE_REF` environment variable, defaulting to `deepseek-harness-docker:test`.
- Produces: an image accepting `docker run -p 127.0.0.1:3080:3080 "$IMAGE_REF"`.

- [ ] **Step 1: Write the failing smoke test**

```sh
#!/usr/bin/env sh
set -eu
image_ref="${IMAGE_REF:-deepseek-harness-docker:test}"
container_id="$(docker run -d --rm -p 127.0.0.1:3080:3080 "$image_ref")"
trap 'docker rm -f "$container_id" >/dev/null 2>&1 || true' EXIT
for attempt in $(seq 1 30); do
  curl --fail --silent --show-error http://127.0.0.1:3080/ >/dev/null && exit 0
  sleep 1
done
docker logs "$container_id"
exit 1
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `IMAGE_REF=deepseek-harness-docker:test sh tests/smoke.sh`

Expected: FAIL because `deepseek-harness-docker:test` does not yet exist.

- [ ] **Step 3: Implement the minimum runtime image**

Create a Node `22.19.0-bookworm-slim` image that installs `tini`, `socat`, `curl`, and `@deepseek-ai/dsh@0.1.0-rc.6`; creates a locked-down `dsh` user; sets `DSH_HOME`; and calls the entrypoint. The entrypoint starts `dsh web` in the background, forwards `0.0.0.0:3080` to `127.0.0.1:3080`, and exits with the DSH process status.

- [ ] **Step 4: Build and verify green**

Run: `docker build --tag deepseek-harness-docker:test . && IMAGE_REF=deepseek-harness-docker:test sh tests/smoke.sh`

Expected: PASS; `curl` receives an HTTP response from the Web UI.

- [ ] **Step 5: Commit**

```bash
git add Dockerfile .dockerignore docker/entrypoint.sh tests/smoke.sh
git commit -m "feat: add pinned DSH container runtime"
```

### Task 2: Local usage contract and documentation

**Files:**
- Create: `compose.yaml`
- Create: `README.md`
- Modify: `tests/smoke.sh`

**Interfaces:**
- Consumes: image built by Task 1.
- Produces: `docker compose up --build` serving only `127.0.0.1:3080` with persisted `dsh-state` volume and `./workspace` mount.

- [ ] **Step 1: Extend the failing smoke test**

Add checks that the image user is `dsh`, `DSH_HOME` is `/home/dsh/.dsh`, and `docker image inspect` returns an `org.opencontainers.image.licenses=MIT` label.

- [ ] **Step 2: Verify red**

Run: `docker build --tag deepseek-harness-docker:test . && IMAGE_REF=deepseek-harness-docker:test sh tests/smoke.sh`

Expected: FAIL until the image user, environment, and OCI label are present.

- [ ] **Step 3: Implement Compose and README**

Set Compose ports to `127.0.0.1:3080:3080`, use a named `dsh-state` volume at `/home/dsh/.dsh`, and bind `./workspace:/workspace`. Document runtime-only credentials, exposed-workspace risk, reverse-proxy/auth requirements, exact image tag/digest usage, and update/release process.

- [ ] **Step 4: Verify green**

Run: `docker build --tag deepseek-harness-docker:test . && IMAGE_REF=deepseek-harness-docker:test sh tests/smoke.sh && docker compose config`

Expected: PASS and Compose configuration shows a loopback-only host port mapping.

- [ ] **Step 5: Commit**

```bash
git add Dockerfile compose.yaml README.md tests/smoke.sh
git commit -m "docs: add safe local DSH usage"
```

### Task 3: CI validation and trusted GHCR release

**Files:**
- Create: `.github/workflows/ci.yml`
- Create: `.github/workflows/publish.yml`
- Create: `.github/workflows/check-upstream.yml`

**Interfaces:**
- Consumes: Dockerfile and `tests/smoke.sh` from Task 1.
- Produces: PR validation and GHCR images named `ghcr.io/${{ github.repository_owner }}/deepseek-harness`.

- [ ] **Step 1: Write the failing workflow contract test**

Create `tests/workflow-contract.sh` that rejects any workflow action reference lacking a 40-character SHA and rejects `packages: write` in `ci.yml`.

- [ ] **Step 2: Verify red**

Run: `sh tests/workflow-contract.sh`

Expected: FAIL because workflow files do not exist.

- [ ] **Step 3: Implement workflows**

`ci.yml` uses read-only permissions, builds the image, and runs `tests/smoke.sh`. `publish.yml` limits execution to `v*` tags and protected manual dispatch, logs in using `GITHUB_TOKEN`, builds/pushes GHCR metadata tags, and generates an artifact attestation using the pushed digest. `check-upstream.yml` uses npm registry metadata and creates an issue when its exact pinned version differs; it never changes the Dockerfile or publishes an image.

- [ ] **Step 4: Verify green**

Run: `sh tests/workflow-contract.sh && docker build --tag deepseek-harness-docker:test . && IMAGE_REF=deepseek-harness-docker:test sh tests/smoke.sh`

Expected: PASS; no workflow exposes credentials or grants package write permission to PR CI.

- [ ] **Step 5: Commit**

```bash
git add .github/workflows tests/workflow-contract.sh
git commit -m "ci: validate and publish DSH image to GHCR"
```
