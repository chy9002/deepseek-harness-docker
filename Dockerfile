FROM node:22.19.0-bookworm-slim

LABEL org.opencontainers.image.title="DeepSeek Harness" \
      org.opencontainers.image.description="Pinned DeepSeek Harness web runtime" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/deepseek-ai/deepseek-harness"

RUN apt-get update \
    && apt-get install --no-install-recommends --yes tini socat curl \
    && npm install --global --omit=dev @deepseek-ai/dsh@0.1.0-rc.6 \
    && npm cache clean --force \
    && groupadd --system dsh \
    && useradd --system --gid dsh --create-home --home-dir /home/dsh dsh \
    && mkdir --parents /home/dsh/.dsh /workspace \
    && chown --recursive dsh:dsh /home/dsh /workspace \
    && rm --recursive --force /var/lib/apt/lists/*

COPY --chown=dsh:dsh docker/entrypoint.sh /usr/local/bin/dsh-entrypoint

ENV DSH_HOME=/home/dsh/.dsh

WORKDIR /workspace
EXPOSE 3080
USER dsh
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/dsh-entrypoint"]
