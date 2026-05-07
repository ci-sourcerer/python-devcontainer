ARG PYTHON_VERSION=3.14

FROM mcr.microsoft.com/devcontainers/python:${PYTHON_VERSION}-bookworm

LABEL org.opencontainers.image.authors="Joseph Asbury <ci_sourcerer@yahoo.com>"

SHELL [ "/bin/zsh", "-c" ]

ARG PIPX_VERSION
ARG POETRY_VERSION
ARG POETHEPOET_VERSION
ARG DUNAMAI_VERSION
ARG POETRY_PLUGIN_EXPORT_VERSION
ARG TWINE_VERSION

USER vscode
    
COPY setup-environment.sh /usr/local/bin/setup-environment
COPY pipx-packages.txt /tmp/pipx-packages.txt

ENV POETRY_VERSION=$POETRY_VERSION
ENV POETHEPOET_VERSION=$POETHEPOET_VERSION
ENV DUNAMAI_VERSION=$DUNAMAI_VERSION
ENV POETRY_PLUGIN_EXPORT_VERSION=$POETRY_PLUGIN_EXPORT_VERSION
ENV PIPX_VERSION=$PIPX_VERSION

RUN --mount=type=cache,target=/home/vscode/.cache/pip \
    set -eu && \
    install_spec() { \
        package="$1"; \
        version="$2"; \
        if [ -n "$version" ]; then \
            printf '%s==%s' "$package" "$version"; \
        else \
            printf '%s' "$package"; \
        fi; \
    } && \
    autoload -Uz compinit && \
    compinit && \
    pip install "$(install_spec pipx "$PIPX_VERSION")" && \
    pipx ensurepath && \
    pipx install argcomplete && \
    while IFS= read -r package; do \
        [ -n "$package" ] || continue; \
        varname="${(U)package}_VERSION"; \
        varname="${varname//-/_}"; \
        version="${(P)varname}"; \
        pipx install "$(install_spec "$package" "$version")"; \
    done </tmp/pipx-packages.txt && \
    pipx inject poetry "$(install_spec poetry-plugin-export "$POETRY_PLUGIN_EXPORT_VERSION")" && \
    mkdir -p /home/vscode/.zfunc && \
    printf 'fpath+=~/.zfunc\ncompinit\n' >>/home/vscode/.zshrc && \
    poetry completions zsh >/home/vscode/.zfunc/_poetry && \
    poe _zsh_completion >/home/vscode/.zfunc/_poe && \
    register-python-argcomplete --shell zsh pipx >/home/vscode/.zfunc/_pipx

    
USER root
    
RUN rm -rf /tmp/pipx-packages.txt