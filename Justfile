# Update and commit the exact tool defaults from PyPI and GitHub.
update-tools:
    @cd "{{justfile_directory()}}" && sh scripts/update-tool-versions.sh
