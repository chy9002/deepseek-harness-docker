# DeepSeek Harness container

This repository builds a pinned, non-root Docker image for the DeepSeek
Harness web UI. The runtime listens on the container's port `3080`; the
included Compose configuration publishes it only on the local loopback
interface.

## Run locally

Create the host workspace directory once, then build and start the service:

```sh
mkdir -p workspace
docker compose up --build
```

Open <http://127.0.0.1:3080/>. Stop it with `Ctrl-C`, or run
`docker compose down`. The named `dsh-state` volume persists DSH state across
container replacement. Remove that state deliberately with
`docker compose down --volumes`.

Compose mounts `./workspace` at `/workspace`, so files created by DSH are
available on the host. Treat that directory as exposed application data and
do not mount secrets, a home directory, or a broader host path into it.

## Credentials and network boundary

Credentials are runtime-only inputs. Supply them through your deployment
secret manager or an ephemeral `docker run`/Compose environment override; do
not put API keys in the Dockerfile, image layers, repository, `compose.yaml`,
`.env` files, mounted workspace, or shell history. Do not bake credentials
into a derived image.

The default Compose port mapping is intentionally
`127.0.0.1:3080:3080`; it is not a public service. If remote access is
required, put an authenticated, TLS-enabled reverse proxy in front of the
loopback endpoint and enforce authorization, rate limits, and any required
network restrictions there. Do not change the mapping to `0.0.0.0` without
providing equivalent access controls.

## Image tags and releases

For reproducible deployments, use an exact published image tag or digest,
for example:

```sh
docker pull ghcr.io/OWNER/deepseek-harness:0.1.0
docker run --rm \
  -p 127.0.0.1:3080:3080 \
  ghcr.io/OWNER/deepseek-harness:0.1.0
```

Pinning by digest (`ghcr.io/OWNER/deepseek-harness@sha256:...`) is strongest;
verify the digest from the trusted release output before promotion. Replace
`OWNER` with the publishing GitHub organization or user.

The Dockerfile pins the DSH npm release. To update it, review the upstream
release, change the exact version intentionally, rebuild, and run the smoke
test. Releases are published to GHCR from a version tag (or an explicitly
authorized manual release) after CI validation. Deploy a new immutable tag or
digest only after reviewing its changelog and security impact; never use
`latest` for production.
