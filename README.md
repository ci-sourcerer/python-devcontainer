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
- [GitHub CLI](https://github.com/cli/cli): A command line interface for GitHub.

### Tool version defaults

[`requirements.txt`](requirements.txt) contains exact default versions for tools installed with `uv tool`.

Build args in `docker-bake.hcl` can override those defaults. The mapping rule is:

- `package-name` maps to `<UPPERCASE_PACKAGE_NAME>_VERSION`
- `-` becomes `_`

For example: `poethepoet` maps to `POETHEPOET_VERSION`.

When an override is provided, the image installs `package==<override>`.

### Development scripts

- [`development_scripts/setup-environment.sh`](development_scripts/setup-environment.sh): A script to set up the development environment once the container is started and the project is cloned into the container. It installs dependencies with Poetry or uv, and sets up pre-commit hooks when configured. Set `PACKAGE_MANAGER` to deterministically choose between Poetry and uv for dependency management.
