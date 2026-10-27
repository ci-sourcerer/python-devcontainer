variable "IMAGE_NAME" {
  type        = string
  description = "The name of the Docker image to build."
  default     = "devcontainer-python"
}

variable "REGISTRY_HOST" {
  type        = string
  description = "Optional registry host to prefix image names, e.g. registry.example.com"
  default     = ""
}

variable "REGISTRY_NAMESPACE" {
  type        = string
  description = "Optional registry namespace (repository/org), e.g. my-org"
  default     = ""
}

variable "POETRY_VERSION" {
  type        = string
  description = "The exact version pin for Poetry. Uses requirements.txt defaults when unset."
  default     = null
}

variable "POETHEPOET_VERSION" {
  type        = string
  description = "The exact version pin for Poethepoet. Uses requirements.txt defaults when unset."
  default     = null
}

variable "DUNAMAI_VERSION" {
  type        = string
  description = "The exact version pin for Dunamai. Uses requirements.txt defaults when unset."
  default     = null
}

variable "POETRY_PLUGIN_EXPORT_VERSION" {
  type        = string
  description = "The exact version pin for Poetry Plugin Export. Uses tool-versions.env defaults when unset."
  default     = null
}

variable "UV_VERSION" {
  type        = string
  description = "The exact version pin for uv. Uses tool-versions.env defaults when unset."
  default     = null
}

variable "ARGCOMPLETE_VERSION" {
  type        = string
  description = "The exact version pin for argcomplete. Uses tool-versions.env defaults when unset."
  default     = null
}

variable "TWINE_VERSION" {
  type        = string
  description = "The exact version pin for Twine. Uses requirements.txt defaults when unset."
  default     = null
}

variable "PYINSTALLER_VERSION" {
  type        = string
  description = "The exact version pin for PyInstaller. Uses requirements.txt defaults when unset."
  default     = null
}

variable "RUFF_VERSION" {
  type        = string
  description = "The exact version pin for Ruff. Uses requirements.txt defaults when unset."
  default     = null
}

variable "PRE_COMMIT_VERSION" {
  type        = string
  description = "The exact version pin for pre-commit. Uses requirements.txt defaults when unset."
  default     = null
}

variable "PIP_AUDIT_VERSION" {
  type        = string
  description = "The exact version pin for pip-audit. Uses requirements.txt defaults when unset."
  default     = null
}

variable "MYPY_VERSION" {
  type        = string
  description = "The exact version pin for mypy. Uses requirements.txt defaults when unset."
  default     = null
}

variable "PYTEST_VERSION" {
  type        = string
  description = "The exact version pin for pytest. Uses requirements.txt defaults when unset."
  default     = null
}

variable "PYTEST_COV_VERSION" {
  type        = string
  description = "The exact version pin for pytest-cov. Uses requirements.txt defaults when unset."
  default     = null
}

variable "PYTEST_XDIST_VERSION" {
  type        = string
  description = "The exact version pin for pytest-xdist. Uses requirements.txt defaults when unset."
  default     = null
}

variable "IPYTHON_VERSION" {
  type        = string
  description = "The exact version pin for IPython. Uses requirements.txt defaults when unset."
  default     = null
}

variable "DEBUGPY_VERSION" {
  type        = string
  description = "The exact version pin for debugpy. Uses requirements.txt defaults when unset."
  default     = null
}

variable "GH_VERSION" {
  type        = string
  description = "The exact version pin for GitHub CLI. Uses tool-versions.env defaults when unset."
  default     = null
}

variable "HADOLINT_VERSION" {
  type        = string
  description = "The exact version pin for hadolint. Uses tool-versions.env defaults when unset."
  default     = null
}

target "base" {
  context = "."
  dockerfile = "Dockerfile"
  args = {
    UV_VERSION                   = UV_VERSION
    ARGCOMPLETE_VERSION          = ARGCOMPLETE_VERSION
    POETRY_VERSION               = POETRY_VERSION
    POETHEPOET_VERSION           = POETHEPOET_VERSION
    DUNAMAI_VERSION              = DUNAMAI_VERSION
    POETRY_PLUGIN_EXPORT_VERSION = POETRY_PLUGIN_EXPORT_VERSION
    TWINE_VERSION                = TWINE_VERSION
    PYINSTALLER_VERSION          = PYINSTALLER_VERSION
    RUFF_VERSION                 = RUFF_VERSION
    PRE_COMMIT_VERSION           = PRE_COMMIT_VERSION
    PIP_AUDIT_VERSION            = PIP_AUDIT_VERSION
    MYPY_VERSION                 = MYPY_VERSION
    PYTEST_VERSION               = PYTEST_VERSION
    PYTEST_COV_VERSION           = PYTEST_COV_VERSION
    PYTEST_XDIST_VERSION         = PYTEST_XDIST_VERSION
    IPYTHON_VERSION              = IPYTHON_VERSION
    DEBUGPY_VERSION              = DEBUGPY_VERSION
    GH_VERSION                   = GH_VERSION
    HADOLINT_VERSION             = HADOLINT_VERSION
  }
}

target "default" {
  inherits = ["base"]
  matrix = {
    PYTHON_VERSION = ["3.11", "3.12", "3.13", "3.14", "3.15"]
  }
  name = "python-${replace(PYTHON_VERSION, ".", "-")}"
  args = {
    PYTHON_VERSION = PYTHON_VERSION
  }
  tags      = ["${join("/", compact([REGISTRY_HOST, REGISTRY_NAMESPACE, IMAGE_NAME]))}:${PYTHON_VERSION}"]
  platforms = ["linux/amd64", "linux/arm64"]
}
