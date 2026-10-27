# Build the default Python-version bake matrix.
build *args:
    docker buildx bake -f docker-bake.hcl default {{args}}

# Build the default bake matrix for a single architecture.
build-amd64 *args:
    docker buildx bake -f docker-bake.hcl --set '*.platform=linux/amd64' default {{args}}

# Build the default bake matrix for a single architecture.
build-arm64 *args:
    docker buildx bake -f docker-bake.hcl --set '*.platform=linux/arm64' default {{args}}

# Fall through to docker buildx bake for custom targets or matrices.
bake *args:
    docker buildx bake -f docker-bake.hcl {{args}}

# Update and commit the exact tool defaults from PyPI and GitHub.
update-tools:
    @cd "{{justfile_directory()}}" && sh scripts/update-tool-versions.sh
