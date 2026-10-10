FROM mcr.microsoft.com/devcontainers/javascript-node:22-bookworm AS node
FROM ghcr.io/astral-sh/uv:0.13.0 AS uv
FROM mcr.microsoft.com/devcontainers/python:1-3.12-bookworm

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# Python comes from the development image. Node is needed by the required AI Feature.
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules/npm /usr/local/lib/node_modules/npm
RUN ln -sf ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -sf ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx
COPY --from=uv /uv /uvx /usr/local/bin/

ENV npm_config_registry=https://registry.npmmirror.com \
    PIP_INDEX_URL=https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple

# The subsequent Feature apt calls inherit these HTTPS sources. Keep Debian signatures.
RUN rm -f /etc/apt/sources.list.d/yarn.list \
    && sed -i \
      -e 's|http://deb.debian.org/debian-security|https://mirrors.tuna.tsinghua.edu.cn/debian-security|g' \
      -e 's|http://deb.debian.org/debian|https://mirrors.tuna.tsinghua.edu.cn/debian|g' \
      -e 's|http://security.debian.org/debian-security|https://mirrors.tuna.tsinghua.edu.cn/debian-security|g' \
      /etc/apt/sources.list.d/debian.sources \
    && rm -f /etc/apt/apt.conf.d/docker-clean \
    && mkdir -p /opt/venv /home/vscode/.cache /home/vscode/.config /home/vscode/.local/share \
    && chown vscode:vscode /opt/venv /home/vscode/.cache /home/vscode/.config /home/vscode/.local /home/vscode/.local/share

# No repository source or Python dependencies enter the build context.
# ai-coding-cli 0.2.7 manages its own apt/npm downloads; it exposes no cache-mount options.
