FROM alpine:latest

# Packages:
#  - bash       Required for entrypoint script execution
#  - curl       Downloads Claude CLI installer at runtime
#  - libstdc++  Runtime libraries for Claude CLI
#  - libgcc     Runtime libraries for Claude CLI
#  - ripgrep    Fast search tool required by Claude Code
#  - shadow     Provides user management utilities (adduser, etc.)
#  - su-exec    Safer alternative to sudo for privilege dropping
RUN apk add --no-cache \
    bash \
    curl \
    libgcc \
    libstdc++ \
    ripgrep \
    shadow \
    su-exec

# Use ripgrep from apk
ENV USE_BUILTIN_RIPGREP=0

RUN addgroup -g 1000 claude && adduser -D -u 1000 -G claude claude

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh
COPY settings.json /home/claude/.claude/settings.json

WORKDIR /workspace

ENV PATH="/home/claude/.local/bin:$PATH"

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
