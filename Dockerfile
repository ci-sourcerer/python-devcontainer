ARG PYTHON_VERSION=3.14

FROM mcr.microsoft.com/devcontainers/python:${PYTHON_VERSION}-bookworm

ARG TARGETOS
ARG TARGETARCH

LABEL org.opencontainers.image.authors="Joseph Asbury <ci_sourcerer@yahoo.com>"

SHELL [ "/bin/zsh", "-c" ]

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

ENV POETRY_VERSION=$POETRY_VERSION
ENV POETHEPOET_VERSION=$POETHEPOET_VERSION
ENV DUNAMAI_VERSION=$DUNAMAI_VERSION
ENV POETRY_PLUGIN_EXPORT_VERSION=$POETRY_PLUGIN_EXPORT_VERSION
ENV PIPX_VERSION=$PIPX_VERSION
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
    while IFS= read -r package; do \
        [ -n "$package" ] || continue; \
        varname="${(U)package}_VERSION"; \
        varname="${varname//-/_}"; \
        version="${(P)varname}"; \
        pipx install "$(install-spec "$package" "$version")"; \
    done </tmp/pipx-packages.txt && \
    pipx inject poetry "$(install-spec poetry-plugin-export "$POETRY_PLUGIN_EXPORT_VERSION")" && \
    poetry completions zsh >/home/vscode/.zfunc/_poetry && \
    poe _zsh_completion >/home/vscode/.zfunc/_poe

USER root

RUN set -eu; \
    GH_VERSION="${GH_VERSION:-$(curl -fsSL 'https://api.github.com/repos/cli/cli/releases/latest' | jq -r '.tag_name' | sed 's/^v//')}"; \
    curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_${TARGETOS}_${TARGETARCH}.tar.gz" \
        | tar -xzf - --strip-components=2 -C /tmp --wildcards "*/bin/gh"; \
    install -Dm755 /tmp/gh /usr/local/bin/gh
RUN rm -rf /tmp/pipx-packages.txt && /tmp/gh
