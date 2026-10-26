#!/bin/sh
set -eu

_requirements=$(mktemp ./requirements.txt.XXXXXX)
_versions=$(mktemp ./tool-versions.env.XXXXXX)
trap 'rm -f "$_requirements" "$_versions"' EXIT
trap 'exit 1' HUP INT TERM

case "${ALLOW_MAJOR_UPDATES:-0}" in
    0|1) ;;
    *) printf 'ALLOW_MAJOR_UPDATES must be 0 or 1\n' >&2; exit 1 ;;
esac

_select_version() {
    if ! printf '%s\n' "$1" | grep -Eq '^[0-9]+(\.[0-9]+)*$'; then
        printf 'Unsupported current version: %s\n' "$1" >&2
        return 1
    fi
    jq -er --arg current "$1" --arg major "${1%%.*}" \
        --arg allow "${ALLOW_MAJOR_UPDATES:-0}" '
        def version_key:
            split(".") | map(tonumber) | . + [0, 0, 0, 0];
        $current as $current_version |
        [ .[] | select(type == "string") | ltrimstr("v") |
          select(test("^[0-9]+(\\.[0-9]+)*$")) |
          select($allow == "1" or split(".")[0] == $major) ] as $versions |
        if ($versions | length) == 0 then
            error("No stable release found for current version " + $current)
        else
            ($versions + [$current_version]) | max_by(version_key)
        end'
}

_pypi_version() {
    _response=$(curl -fsSL "https://pypi.org/pypi/$1/json")
    _available=$(printf '%s\n' "$_response" | jq -e '
        [.releases | to_entries[] |
         select(any(.value[]; .yanked == false)) | .key]')
    printf '%s\n' "$_available" | _select_version "$2"
}

_github_version() {
    _page=1
    _releases='[]'
    while :; do
        _response=$(curl -fsSL \
            "https://api.github.com/repos/$1/releases?per_page=100&page=$_page")
        _count=$(printf '%s\n' "$_response" | jq -er 'length')
        _releases=$(printf '%s\n%s\n' "$_releases" "$_response" |
            jq -es '.[0] + [.[1][] | select(.draft == false and
                .prerelease == false) | .tag_name]')
        [ "$_count" -eq 100 ] || break
        _page=$((_page + 1))
    done
    printf '%s\n' "$_releases" | _select_version "$2"
}

while IFS= read -r _line || [ -n "$_line" ]; do
    case "$_line" in
        ''|'#'*) printf '%s\n' "$_line" >> "$_requirements" ;;
        *)
            if ! printf '%s\n' "$_line" | grep -Eq \
                '^[A-Za-z0-9][A-Za-z0-9._-]*==[0-9][A-Za-z0-9.!+_-]*$'; then
                printf 'Unsupported requirement: %s\n' "$_line" >&2
                exit 1
            fi
            _package=${_line%%==*}
            _version=$(_pypi_version "$_package" "${_line#*==}")
            printf '%s==%s\n' "$_package" "$_version" >> "$_requirements"
            printf '%s: %s -> %s\n' "$_package" "${_line#*==}" "$_version"
            ;;
    esac
done < requirements.txt

_seen=' '
while IFS= read -r _line || [ -n "$_line" ]; do
    case "$_line" in
        ''|'#'*) printf '%s\n' "$_line" >> "$_versions"; continue ;;
    esac
    _name=${_line%%=*}
    case "$_seen" in
        *" $_name "*) printf 'Duplicate default: %s\n' "$_name" >&2; exit 1 ;;
    esac
    _seen="$_seen$_name "
    case "$_name" in
        DEFAULT_UV_VERSION) _version=$(_pypi_version uv "${_line#*=}") ;;
        DEFAULT_ARGCOMPLETE_VERSION) _version=$(_pypi_version argcomplete "${_line#*=}") ;;
        DEFAULT_POETRY_PLUGIN_EXPORT_VERSION)
            _version=$(_pypi_version poetry-plugin-export "${_line#*=}") ;;
        DEFAULT_GH_VERSION) _version=$(_github_version cli/cli "${_line#*=}") ;;
        DEFAULT_HADOLINT_VERSION) _version=$(_github_version hadolint/hadolint "${_line#*=}") ;;
        *) printf 'Unsupported default: %s\n' "$_line" >&2; exit 1 ;;
    esac
    if ! printf '%s\n' "$_line" | grep -Eq \
        '^[A-Z_]+=[0-9][A-Za-z0-9.!+_-]*$'; then
        printf 'Invalid default: %s\n' "$_line" >&2
        exit 1
    fi
    printf '%s=%s\n' "$_name" "$_version" >> "$_versions"
    printf '%s: %s -> %s\n' "$_name" "${_line#*=}" "$_version"
done < tool-versions.env

for _name in DEFAULT_UV_VERSION DEFAULT_ARGCOMPLETE_VERSION \
    DEFAULT_POETRY_PLUGIN_EXPORT_VERSION DEFAULT_GH_VERSION \
    DEFAULT_HADOLINT_VERSION; do
    case "$_seen" in
        *" $_name "*) ;;
        *) printf 'Missing default: %s\n' "$_name" >&2; exit 1 ;;
    esac
done

chmod 644 "$_requirements" "$_versions"
mv "$_requirements" requirements.txt
mv "$_versions" tool-versions.env
