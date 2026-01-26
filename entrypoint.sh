#!/bin/bash
set -e

USER_ID="${HOST_UID:-1000}"
GROUP_ID="${HOST_GID:-1000}"

# Validate UID/GID are numeric to prevent injection
if ! [[ "$USER_ID" =~ ^[0-9]+$ ]] || ! [[ "$GROUP_ID" =~ ^[0-9]+$ ]]; then
    echo "Error: Invalid HOST_UID or HOST_GID - must be numeric" >&2
    exit 1
fi

chown -R "$USER_ID:$GROUP_ID" /home/claude

# When GITHUB_TOKEN is available, configure git to use HTTPS+token instead of SSH
if [ -n "${GITHUB_TOKEN:-}" ]; then
    gosu "${USER_ID}:${GROUP_ID}" git config --global url."https://github.com/".insteadOf "git@github.com:"
    gosu "${USER_ID}:${GROUP_ID}" git config --global credential.helper '!f() { echo "password=${GITHUB_TOKEN}"; }; f'
fi

if [ ! -f /home/claude/.local/bin/claude ]; then
    echo "⚡ curl -fsSL https://claude.ai/install.sh | bash"
    INSTALL_SCRIPT="/tmp/claude-install-$$.sh"

    # Download with verification
    if ! gosu "${USER_ID}:${GROUP_ID}" curl -fsSL -o "${INSTALL_SCRIPT}" https://claude.ai/install.sh; then
        echo "Error: Failed to download Claude CLI installer" >&2
        exit 1
    fi

    # Basic safety check - verify it's a shell script
    if ! head -n1 "${INSTALL_SCRIPT}" | grep -q '^#!/'; then
        echo "Error: Downloaded file is not a valid shell script" >&2
        rm -f "${INSTALL_SCRIPT}"
        exit 1
    fi

    # Execute with cleanup
    gosu "${USER_ID}:${GROUP_ID}" bash "${INSTALL_SCRIPT}" stable
    rm -f "${INSTALL_SCRIPT}"
fi

exec gosu "${USER_ID}:${GROUP_ID}" "$@"
