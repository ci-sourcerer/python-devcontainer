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
ARG RUFF_VERSION
ARG PRE_COMMIT_VERSION
ARG PIP_AUDIT_VERSION
ARG MYPY_VERSION
ARG PYTEST_VERSION
ARG PYTEST_COV_VERSION
ARG PYTEST_XDIST_VERSION
ARG IPYTHON_VERSION
ARG DEBUGPY_VERSION
ARG GH_VERSION
ARG HADOLINT_VERSION

USER vscode

ENV PATH=/home/vscode/.local/bin:$PATH
    
COPY --link development_scripts/*.sh /usr/local/bin/
COPY requirements.txt tool-versions.env /tmp/

ENV UV_VERSION=$UV_VERSION
ENV ARGCOMPLETE_VERSION=$ARGCOMPLETE_VERSION
ENV POETRY_VERSION=$POETRY_VERSION
ENV POETHEPOET_VERSION=$POETHEPOET_VERSION
ENV DUNAMAI_VERSION=$DUNAMAI_VERSION
ENV POETRY_PLUGIN_EXPORT_VERSION=$POETRY_PLUGIN_EXPORT_VERSION
ENV TWINE_VERSION=$TWINE_VERSION
ENV PYINSTALLER_VERSION=$PYINSTALLER_VERSION
ENV RUFF_VERSION=$RUFF_VERSION
ENV PRE_COMMIT_VERSION=$PRE_COMMIT_VERSION
ENV PIP_AUDIT_VERSION=$PIP_AUDIT_VERSION
ENV MYPY_VERSION=$MYPY_VERSION
ENV PYTEST_VERSION=$PYTEST_VERSION
ENV PYTEST_COV_VERSION=$PYTEST_COV_VERSION
ENV PYTEST_XDIST_VERSION=$PYTEST_XDIST_VERSION
ENV IPYTHON_VERSION=$IPYTHON_VERSION
ENV DEBUGPY_VERSION=$DEBUGPY_VERSION
ENV GH_VERSION=$GH_VERSION
ENV HADOLINT_VERSION=$HADOLINT_VERSION

RUN mkdir -p /home/vscode/.zfunc && \
    printf 'fpath+=~/.zfunc\ncompinit\n' >>/home/vscode/.zshrc && \
    printf 'export UV_CACHE_DIR="${UV_CACHE_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)/.uv-cache}"\n' >>/home/vscode/.zshrc

USER root

ENV UV_TOOL_BIN_DIR=/home/vscode/.local/bin

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked apt-get update && \
    apt-get install -y --no-install-recommends shellcheck shfmt && \
    rm -rf /var/lib/apt/lists/*

RUN --mount=type=cache,target=/root/.cache/pip \
    set -eu && \
    autoload -Uz compinit && \
    compinit && \
    . /tmp/tool-versions.env && \
    PIP_ROOT_USER_ACTION=ignore pip install "uv==${UV_VERSION:-$DEFAULT_UV_VERSION}" \
        "argcomplete==${ARGCOMPLETE_VERSION:-$DEFAULT_ARGCOMPLETE_VERSION}"

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
    . /tmp/tool-versions.env && \
    POETRY_PLUGIN_EXPORT_VERSION="${POETRY_PLUGIN_EXPORT_VERSION:-$DEFAULT_POETRY_PLUGIN_EXPORT_VERSION}" && \
    poetry self add "poetry-plugin-export==${POETRY_PLUGIN_EXPORT_VERSION}" && \
    poetry completions zsh >/home/vscode/.zfunc/_poetry && \
    poe _zsh_completion >/home/vscode/.zfunc/_poe

USER root

RUN set -eu; \
    . /tmp/tool-versions.env; \
    GH_VERSION_INPUT="${GH_VERSION:-$DEFAULT_GH_VERSION}"; \
    if printf '%s' "$GH_VERSION_INPUT" | grep -Eq '^[0-9]+(\.[0-9]+)?$'; then \
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

RUN set -eu; \
    . /tmp/tool-versions.env; \
    HADOLINT_VERSION="${HADOLINT_VERSION:-$DEFAULT_HADOLINT_VERSION}"; \
    case "$TARGETOS" in \
        linux) HADOLINT_OS="Linux" ;; \
        *) printf 'Unsupported TARGETOS for hadolint: %s\n' "$TARGETOS" >&2; exit 1 ;; \
    esac; \
    case "$TARGETARCH" in \
        amd64) HADOLINT_ARCH="x86_64" ;; \
        arm64) HADOLINT_ARCH="arm64" ;; \
        *) printf 'Unsupported TARGETARCH for hadolint: %s\n' "$TARGETARCH" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-${HADOLINT_OS}-${HADOLINT_ARCH}" \
        -o /usr/local/bin/hadolint && \
    chmod +x /usr/local/bin/hadolint

RUN rm -rf /tmp/requirements.txt /tmp/tool-versions.env /tmp/gh

WORKDIR /home/vscode
ENTRYPOINT [ "/usr/bin/zsh" ]
