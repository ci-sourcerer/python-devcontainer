ARG PYTHON_VERSION=3.14

FROM mcr.microsoft.com/devcontainers/python:${PYTHON_VERSION}-bookworm

ARG TARGETOS
ARG TARGETARCH

LABEL org.opencontainers.image.authors="Joseph Asbury <ci_sourcerer@yahoo.com>"

SHELL [ "/bin/zsh", "-c" ]

ENV POETRY_VIRTUALENVS_IN_PROJECT=true
ENV PATH="/usr/local/bin:$PATH"

ARG UV_VERSION
ARG ARGCOMPLETE_VERSION
ARG POETRY_VERSION
ARG POETHEPOET_VERSION
ARG DUNAMAI_VERSION
ARG POETRY_PLUGIN_EXPORT_VERSION
ARG TWINE_VERSION
ARG PYINSTALLER_VERSION
ARG GH_VERSION

USER vscode

ENV PATH=/home/vscode/.local/bin:$PATH
    
COPY --link development_scripts/*.sh /usr/local/bin/
COPY requirements.txt /tmp/requirements.txt

ENV UV_VERSION=$UV_VERSION
ENV ARGCOMPLETE_VERSION=$ARGCOMPLETE_VERSION
ENV POETRY_VERSION=$POETRY_VERSION
ENV POETHEPOET_VERSION=$POETHEPOET_VERSION
ENV DUNAMAI_VERSION=$DUNAMAI_VERSION
ENV POETRY_PLUGIN_EXPORT_VERSION=$POETRY_PLUGIN_EXPORT_VERSION
ENV TWINE_VERSION=$TWINE_VERSION
ENV PYINSTALLER_VERSION=$PYINSTALLER_VERSION
ENV GH_VERSION=$GH_VERSION

RUN mkdir -p /home/vscode/.zfunc && \
    printf 'fpath+=~/.zfunc\ncompinit\n' >>/home/vscode/.zshrc && \
    printf 'export UV_CACHE_DIR="${UV_CACHE_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)/.uv-cache}"\n' >>/home/vscode/.zshrc

USER root

ENV UV_TOOL_BIN_DIR=/home/vscode/.local/bin

RUN --mount=type=cache,target=/root/.cache/pip \
    set -eu && \
    autoload -Uz compinit && \
    compinit && \
    UV_INSTALL="uv" && \
    ARGCOMPLETE_INSTALL="argcomplete" && \
    if [ -n "${UV_VERSION:-}" ]; then UV_INSTALL="uv==${UV_VERSION}"; fi && \
    if [ -n "${ARGCOMPLETE_VERSION:-}" ]; then ARGCOMPLETE_INSTALL="argcomplete==${ARGCOMPLETE_VERSION}"; fi && \
    PIP_ROOT_USER_ACTION=ignore pip install "$UV_INSTALL" "$ARGCOMPLETE_INSTALL"

USER vscode

RUN --mount=type=cache,target=/root/.cache/pip \
    --mount=type=cache,target=/root/.cache/uv \
    set -eu && \
    while read -r requirement; do \
        [ -n "$requirement" ] || continue; \
        case "$requirement" in \
            \#*) continue ;; \
        esac; \
        package="${requirement%%==*}"; \
        default_version="${requirement#*==}"; \
        [ "$package" != "$requirement" ] || { \
            printf 'Invalid requirement entry: %s\\n' "$requirement" >&2; \
            exit 1; \
        }; \
        version_arg="${(U)package}_VERSION"; \
        version_arg="${version_arg//-/_}"; \
        override_version="${(P)version_arg:-}"; \
        version="${override_version:-$default_version}"; \
        if printf '%s' "$version" | grep -Eq '[[:space:]><=!~]'; then \
            printf 'Invalid exact version for %s: %s\n' "$package" "$version" >&2; \
            exit 1; \
        fi; \
        uv tool install "${package}==${version}"; \
    done </tmp/requirements.txt && \
    POETRY_PLUGIN_EXPORT_VERSION="${POETRY_PLUGIN_EXPORT_VERSION:-1.8.0}" && \
    poetry self add "poetry-plugin-export==${POETRY_PLUGIN_EXPORT_VERSION}" && \
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
    install -Dm755 /tmp/gh /usr/local/bin/gh \
    && gh completion -s zsh >/usr/local/share/zsh/site-functions/_gh

RUN rm -rf /tmp/requirements.txt /tmp/gh

WORKDIR /home/vscode
ENTRYPOINT [ "/usr/bin/zsh" ]
