# DeepSeek Harness Docker Image Design

## Goal

Publish a reproducible Docker image for the official `@deepseek-ai/dsh` npm launcher to GitHub Container Registry (GHCR). The image must run the DeepSeek Harness Web UI safely enough for local or reverse-proxy deployment.

## Scope

- A standalone public repository named `deepseek-harness-docker`.
- A Node 22 Debian-slim runtime image installing one exact `@deepseek-ai/dsh` version.
- An entrypoint that leaves DSH on its default loopback listener and uses an in-container TCP proxy for Docker port publishing.
- Docker Compose sample, README, container smoke tests, and GHCR publishing workflow.
- Manual releases and a scheduled, non-publishing update check; publishing always requires a tag or explicit dispatch.

## Non-goals

- Forking, modifying, or rebuilding the DeepSeek Harness monorepo.
- Adding TLS, authentication, or a public-internet deployment configuration.
- Baking API keys, workspaces, or user data into the image.
- Promoting unreviewed upstream versions automatically.

## Architecture

The image installs `@deepseek-ai/dsh` using an exact version argument recorded in the Dockerfile. `dsh web` keeps its documented loopback default on port 3080. `socat` listens on the image's public port and forwards only within the container to that loopback listener, allowing `docker run -p` without relying on an unsupported DSH all-interface bind.

State is stored under `$DSH_HOME` and is intended to be mounted as a named volume. Project files are explicitly bind-mounted at `/workspace`. API credentials are supplied only at runtime, through supported DSH configuration or runtime secrets/environment variables.

## Release and Security Model

The release workflow publishes `ghcr.io/<owner>/deepseek-harness` on version tags and manually-dispatched version builds. It uses `GITHUB_TOKEN` with minimum permissions, immutable SHA-pinned actions, OCI source and version labels, SBOM/provenance attestation, and a smoke-test job before push. Pull requests build but cannot publish.

A scheduled workflow only checks whether npm has a newer stable/RC package version and opens an issue with the candidate version. A maintainer changes the pinned version through a normal reviewed pull request, then creates a release tag. Image tags include the release version and a commit-SHA tag; `latest` moves only after a successful tagged release.

## Acceptance Criteria

1. A credential-free `docker build` succeeds and image labels identify DSH version and source repository.
2. `docker compose up` serves the Web UI through `127.0.0.1:3080`, while the DSH process itself remains loopback-bound.
3. The image runs as a non-root user, persists `$DSH_HOME`, and uses an explicit workspace mount.
4. API keys are absent from Dockerfile, image history, examples, test fixtures, and workflow logs.
5. Pull-request CI builds and smoke-tests the image; release CI publishes only to GHCR and emits an attestation.
6. The README warns that the exposed UI has no built-in public-network authentication and gives digest/tag-pinned run examples.
