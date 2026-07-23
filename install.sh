#!/bin/sh

set -eu

SOURCE_URL=${BGT_DEV_UPDATE_URL:-https://raw.githubusercontent.com/it-nsk/dev-scripts/dev/bin/bgt-dev}
INSTALL_DIR=${BGT_DEV_INSTALL_DIR:-/usr/local/bin}
DESTINATION=$INSTALL_DIR/bgt-dev
tmp=$(mktemp "${TMPDIR:-/tmp}/bgt-dev.XXXXXX")
trap 'rm -f "$tmp"' EXIT HUP INT TERM

command -v curl >/dev/null 2>&1 || {
    printf 'ERROR: curl is required\n' >&2
    exit 1
}

curl -fsSL "$SOURCE_URL" -o "$tmp"
chmod +x "$tmp"
"$tmp" version >/dev/null

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

trap - EXIT HUP INT TERM
printf 'Installed bgt-dev to %s\n' "$DESTINATION"
