# Python Dev Container

This is a Python development container configuration for Visual Studio Code's Dev Containers feature. It includes a Dockerfile and a Docker Bake file for building the images. Just run `docker bake`.

## Inclusions

### CLI tools

- [Poetry](https://python-poetry.org/): A dependency management and packaging tool for Python.
- [Poe the Poet](https://github.com/nat-n/poethepoet): A task runner for Python projects.
- [Dunamai](https://github.com/mtkennerly/dunamai): A tool for generating version numbers based on VCS tags.
- [Poetry Plugin Export](https://github.com/python-poetry/poetry-plugin-export): A plugin for Poetry to export dependencies to requirements files.
- [pipx](https://pipx.pypa.io/stable/): A tool to install and run Python applications in isolated environments.
- [Twine](https://twine.readthedocs.io/en/stable/): A utility for publishing Python packages on PyPI.

### Development scripts

- `[install-spec](./install-spec)`: A script to generate a `requirements.txt`-style content from a spec.
- `[setup-environment.sh](./setup-environment.sh)`: A script to set up the development environment once the container is started and the project being worked on is cloned into the container. Installs Poetry dependencies and sets up the pre-commit hooks if any.

### pipx package list

The file `pipx-packages.txt` defines extra pipx-installed tools in the format `<package>`.

Version build arg names are derived automatically from package names as `<UPPERCASE_PACKAGE_NAME>_VERSION`, with `-` replaced by `_`.

Current entries:

- `poethepoet`
- `dunamai`
- `twine`

The corresponding build args are defined in `docker-bake.hcl` and passed into `Dockerfile`.
