FROM mcr.microsoft.com/devcontainers/universal:2

# The universal image includes: Go, Node, Python, Java, .NET, Ruby, PHP, Rust,
# git, gh, curl, jq, ripgrep, make, gcc, and many other dev tools.

# gosu is needed by the entrypoint for UID/GID remapping with exec semantics
RUN rm -f /etc/apt/sources.list.d/yarn.list && \
    apt-get update && apt-get install -y --no-install-recommends gosu && \
    rm -rf /var/lib/apt/lists/*

# Use ripgrep from the image
ENV USE_BUILTIN_RIPGREP=0

# Copy host .gitconfig if provided (optional, see install.sh)
COPY .gitconfi[g] /home/codespace/

# Install Claude CLI at build time so it's baked into the image
USER codespace
RUN curl -fsSL https://claude.ai/install.sh | bash
USER root

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

WORKDIR /workspace
ENV PATH="/home/codespace/.local/bin:$PATH"

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
