# Python Dev Container

This is a Python development container configuration for Visual Studio Code's Dev Containers feature. It includes a Dockerfile and a Docker Bake file for building the images. Just run `docker bake`.

## Inclusions

### CLI tools

- [uv](https://docs.astral.sh/uv/): The primary tool installer for Python CLI tools.
- [Poetry](https://python-poetry.org/): A dependency management and packaging tool for Python.
- [Poe the Poet](https://github.com/nat-n/poethepoet): A task runner for Python projects.
- [Dunamai](https://github.com/mtkennerly/dunamai): A tool for generating version numbers based on VCS tags.
- [Poetry Plugin Export](https://github.com/python-poetry/poetry-plugin-export): A plugin installed into Poetry to export dependencies to requirements files.
- [Twine](https://twine.readthedocs.io/en/stable/): A utility for publishing Python packages on PyPI.
- [PyInstaller](https://pyinstaller.org/): A tool to bundle Python applications.
- [Ruff](https://docs.astral.sh/ruff/): A fast linter and formatter for Python.
- [pre-commit](https://pre-commit.com/): A framework for managing and maintaining Git hooks.
- [pip-audit](https://pypi.org/project/pip-audit/): A tool for auditing Python environments for vulnerable packages.
- [mypy](https://mypy-lang.org/): A static type checker for Python.
- [pytest](https://docs.pytest.org/): A testing framework for Python.
- [pytest-cov](https://pytest-cov.readthedocs.io/): A coverage plugin for pytest.
- [pytest-xdist](https://pytest-xdist.readthedocs.io/): A plugin for running pytest in parallel.
- [IPython](https://ipython.org/): An enhanced interactive Python shell.
- [debugpy](https://github.com/microsoft/debugpy): A debugger for Python.
- [GitHub CLI](https://github.com/cli/cli): A command line interface for GitHub.
- [shellcheck](https://www.shellcheck.net/): A static analysis tool for shell scripts.
- [shfmt](https://github.com/mvdan/sh): A shell script formatter.
- [hadolint](https://github.com/hadolint/hadolint): A linter for Dockerfiles.

### Tool version defaults

[`requirements.txt`](requirements.txt) contains exact default versions for tools installed with `uv tool`. [`tool-versions.env`](tool-versions.env) contains defaults for uv, argcomplete, Poetry Plugin Export, GitHub CLI, and hadolint.

Build args in `docker-bake.hcl` can override those defaults. The mapping rule for packages in `requirements.txt` is as follows.

- `package-name` maps to `<UPPERCASE_PACKAGE_NAME>_VERSION`
- `-` becomes `_`

For example: `poethepoet` maps to `POETHEPOET_VERSION`.

When an override is provided, the image installs `package==<override>`.

### Development scripts

- [`development_scripts/setup-environment.sh`](development_scripts/setup-environment.sh): A script to set up the development environment once the container is started and the project is cloned into the container. It installs dependencies with Poetry or uv, and sets up pre-commit hooks when configured. Set `PACKAGE_MANAGER` to deterministically choose between Poetry and uv for dependency management.

## Updating tool versions

Run `just update-tools` to update the exact tool defaults from PyPI and GitHub within their current major versions. Run `ALLOW_MAJOR_UPDATES=1 just update-tools` to include major version upgrades. Version 0.x releases are treated as major version 0. The updater considers stable numeric release versions and skips prereleases. This requires `just`, `curl`, and `jq`. Review the changes and rebuild the images to check compatibility with the supported Python versions. The Python image matrix is managed in `docker-bake.hcl`; shellcheck and shfmt are supplied by Debian and follow the base image package repositories.
