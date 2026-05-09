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
  description = "The version of Poetry to install."
  default     = null
}

variable "POETHEPOET_VERSION" {
  type        = string
  description = "The version of Poethepoet to install."
  default     = null
}

variable "DUNAMAI_VERSION" {
  type        = string
  description = "The version of Dunamai to install."
  default     = null
}

variable "POETRY_PLUGIN_EXPORT_VERSION" {
  type        = string
  description = "The version of Poetry Plugin Export to install."
  default     = null
}

variable "PIPX_VERSION" {
  type        = string
  description = "The version of Pipx to install."
  default     = null
}

variable "GH_VERSION" {
  type        = string
  description = "The version of the GitHub CLI to install."
  default     = null
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
  tags = ["${join("/", compact([REGISTRY_HOST, REGISTRY_NAMESPACE, IMAGE_NAME]))}:${PYTHON_VERSION}"]
}
