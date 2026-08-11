#!/bin/sh

set -eu

SOURCE_URL=${DEV_TOOLS_UPDATE_URL:-https://raw.githubusercontent.com/it-nsk/dev-scripts/dev/bin/dev-tools-global}
INSTALL_DIR=${DEV_TOOLS_INSTALL_DIR:-/usr/local/bin}
COMPLETION_DIR=${DEV_TOOLS_COMPLETION_DIR:-/usr/local/share/zsh/site-functions}
DESTINATION=$INSTALL_DIR/dev-tools
tmp=$(mktemp "${TMPDIR:-/tmp}/dev-tools.XXXXXX")
completion_tmp=$(mktemp "${TMPDIR:-/tmp}/dev-tools-completion.XXXXXX")
trap 'rm -f "$tmp" "$completion_tmp"' EXIT HUP INT TERM

command -v curl >/dev/null 2>&1 || {
    printf 'ERROR: curl is required\n' >&2
    exit 1
}

curl -fsSL "$SOURCE_URL" -o "$tmp"
chmod +x "$tmp"
"$tmp" version >/dev/null
"$tmp" completion zsh >"$completion_tmp"

if [ ! -d "$INSTALL_DIR" ] && [ -w "$(dirname "$INSTALL_DIR")" ]; then
    mkdir -p "$INSTALL_DIR"
fi

if [ -w "$INSTALL_DIR" ]; then
    install -m 0755 "$tmp" "$DESTINATION"
elif command -v sudo >/dev/null 2>&1; then
    sudo install -m 0755 "$tmp" "$DESTINATION"
else
    printf 'ERROR: cannot write to %s and sudo is not available\n' "$INSTALL_DIR" >&2
    exit 1
fi

if [ ! -d "$COMPLETION_DIR" ]; then
    mkdir -p "$COMPLETION_DIR" 2>/dev/null \
        || { command -v sudo >/dev/null 2>&1 && sudo mkdir -p "$COMPLETION_DIR"; } \
        || { printf 'ERROR: cannot create %s\n' "$COMPLETION_DIR" >&2; exit 1; }
fi

if [ -w "$COMPLETION_DIR" ]; then
    install -m 0644 "$completion_tmp" "$COMPLETION_DIR/_dev-tools"
elif command -v sudo >/dev/null 2>&1; then
    sudo install -m 0644 "$completion_tmp" "$COMPLETION_DIR/_dev-tools"
else
    printf 'ERROR: cannot install Zsh completion to %s\n' "$COMPLETION_DIR" >&2
    exit 1
fi

trap - EXIT HUP INT TERM
printf 'Installed dev-tools to %s\n' "$DESTINATION"
printf 'Installed Zsh completion to %s\n' "$COMPLETION_DIR/_dev-tools"
