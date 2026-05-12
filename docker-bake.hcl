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
  description = "The major version pin for Poetry."
  default     = "2"
}

variable "POETHEPOET_VERSION" {
  type        = string
  description = "The major version pin for Poethepoet."
  default     = "0"
}

variable "DUNAMAI_VERSION" {
  type        = string
  description = "The major version pin for Dunamai."
  default     = "1"
}

variable "POETRY_PLUGIN_EXPORT_VERSION" {
  type        = string
  description = "The major version pin for Poetry Plugin Export."
  default     = "1"
}

variable "PIPX_VERSION" {
  type        = string
  description = "The major version pin for pipx."
  default     = "1"
}

variable "TWINE_VERSION" {
  type        = string
  description = "The major version pin for Twine."
  default     = "6"
}

variable "GH_VERSION" {
  type        = string
  description = "The major version pin for GitHub CLI."
  default     = "2"
}

target "base" {
  context = "."
  dockerfile = "Dockerfile"
  args = {
    POETRY_VERSION               = POETRY_VERSION
    POETHEPOET_VERSION           = POETHEPOET_VERSION
    DUNAMAI_VERSION              = DUNAMAI_VERSION
    POETRY_PLUGIN_EXPORT_VERSION = POETRY_PLUGIN_EXPORT_VERSION
    PIPX_VERSION                 = PIPX_VERSION
    TWINE_VERSION                = TWINE_VERSION
    GH_VERSION                   = GH_VERSION
  }
}

target "default" {
  inherits = ["base"]
  matrix = {
    PYTHON_VERSION = ["3.10", "3.11", "3.12", "3.13", "3.14"]
  }
  name = "python-${replace(PYTHON_VERSION, ".", "-")}"
  args = {
    PYTHON_VERSION = PYTHON_VERSION
  }
  tags      = ["${join("/", compact([REGISTRY_HOST, REGISTRY_NAMESPACE, IMAGE_NAME]))}:${PYTHON_VERSION}"]
  platforms = ["linux/amd64", "linux/arm64"]
}
