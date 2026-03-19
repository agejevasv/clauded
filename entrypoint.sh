#!/bin/bash
set -e

USER_ID="${HOST_UID:-1000}"
GROUP_ID="${HOST_GID:-1000}"
USER_HOME="/home/codespace"

# Validate UID/GID are numeric to prevent injection
if ! [[ "$USER_ID" =~ ^[0-9]+$ ]] || ! [[ "$GROUP_ID" =~ ^[0-9]+$ ]]; then
    echo "Error: Invalid HOST_UID or HOST_GID - must be numeric" >&2
    exit 1
fi

# Remap the codespace user's UID/GID to match the host when they differ.
# This avoids a slow chown -R on the entire home directory (~GB of dev tools).
if [ "$USER_ID" != "1000" ] || [ "$GROUP_ID" != "1000" ]; then
    groupmod -o -g "$GROUP_ID" codespace 2>/dev/null || true
    usermod -o -u "$USER_ID" -g "$GROUP_ID" codespace 2>/dev/null || true
fi

# Only chown Claude-specific directories (small and fast)
chown -R "$USER_ID:$GROUP_ID" "$USER_HOME/.claude" 2>/dev/null || true
mkdir -p "$USER_HOME/.local"
chown -R "$USER_ID:$GROUP_ID" "$USER_HOME/.local" 2>/dev/null || true

# When GITHUB_TOKEN is available, configure git to use HTTPS+token instead of SSH
if [ -n "${GITHUB_TOKEN:-}" ]; then
    gosu "$USER_ID:$GROUP_ID" git config --global url."https://github.com/".insteadOf "git@github.com:"
    gosu "$USER_ID:$GROUP_ID" git config --global credential.helper '!f() { echo "password=${GITHUB_TOKEN}"; }; f'
fi

exec gosu "$USER_ID:$GROUP_ID" "$@"
