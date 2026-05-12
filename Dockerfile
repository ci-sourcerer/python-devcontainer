ARG PYTHON_VERSION=3.14

FROM mcr.microsoft.com/devcontainers/python:${PYTHON_VERSION}-bookworm

ARG TARGETOS
ARG TARGETARCH

LABEL org.opencontainers.image.authors="Joseph Asbury <ci_sourcerer@yahoo.com>"

SHELL [ "/bin/zsh", "-c" ]

ENV POETRY_VIRTUALENVS_IN_PROJECT=true

ARG PIPX_VERSION
ARG POETRY_VERSION
ARG POETHEPOET_VERSION
ARG DUNAMAI_VERSION
ARG POETRY_PLUGIN_EXPORT_VERSION
ARG TWINE_VERSION
ARG GH_VERSION

USER vscode
    
COPY development_scripts/* /usr/local/bin/
COPY pipx-packages.txt /tmp/pipx-packages.txt

ENV PIPX_VERSION=$PIPX_VERSION
ENV POETRY_VERSION=$POETRY_VERSION
ENV POETHEPOET_VERSION=$POETHEPOET_VERSION
ENV DUNAMAI_VERSION=$DUNAMAI_VERSION
ENV POETRY_PLUGIN_EXPORT_VERSION=$POETRY_PLUGIN_EXPORT_VERSION
ENV TWINE_VERSION=$TWINE_VERSION
ENV GH_VERSION=$GH_VERSION

RUN mkdir -p /home/vscode/.zfunc && \
    printf 'fpath+=~/.zfunc\ncompinit\n' >>/home/vscode/.zshrc

RUN --mount=type=cache,target=/home/vscode/.cache/pip \
    set -eu && \
    autoload -Uz compinit && \
    compinit && \
    pip install "$(install-spec pipx "$PIPX_VERSION")" && \
    pipx ensurepath && \
    pipx install argcomplete && \
    register-python-argcomplete --shell zsh pipx >/home/vscode/.zfunc/_pipx

RUN --mount=type=cache,target=/home/vscode/.cache/pip \
    set -eu && \
    pipx install "$(install-spec poetry "$POETRY_VERSION")" && \
    while read -r package; do \
        [ -n "$package" ] || continue; \
        case "$package" in \
            \#*) continue ;; \
        esac; \
        version_arg="${(U)package}_VERSION"; \
        version_arg="${version_arg//-/_}"; \
        version="${(P)version_arg}"; \
        pipx install "$(install-spec "$package" "$version")"; \
    done </tmp/pipx-packages.txt && \
    poetry completions zsh >/home/vscode/.zfunc/_poetry && \
    poe _zsh_completion >/home/vscode/.zfunc/_poe

USER root

RUN set -eu; \
    GH_VERSION_INPUT="${GH_VERSION:-}"; \
    if [ -z "$GH_VERSION_INPUT" ]; then \
        GH_VERSION="$(curl -fsSL 'https://api.github.com/repos/cli/cli/releases/latest' | jq -r '.tag_name' | sed 's/^v//')"; \
    elif printf '%s' "$GH_VERSION_INPUT" | grep -Eq '^[0-9]+(\.[0-9]+)?$'; then \
        GH_PREFIX="v${GH_VERSION_INPUT}."; \
        GH_VERSION="$(curl -fsSL 'https://api.github.com/repos/cli/cli/releases?per_page=100' \
            | jq -r --arg prefix "$GH_PREFIX" '[.[].tag_name | select(startswith($prefix))][0]' \
            | sed 's/^v//')"; \
        [ -n "$GH_VERSION" ] && [ "$GH_VERSION" != "null" ]; \
    else \
        GH_VERSION="$GH_VERSION_INPUT"; \
    fi; \
    curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_${TARGETOS}_${TARGETARCH}.tar.gz" \
        | tar -xzf - --strip-components=2 -C /tmp --wildcards "*/bin/gh"; \
    install -Dm755 /tmp/gh /usr/local/bin/gh
RUN rm -rf /tmp/pipx-packages.txt /tmp/gh
