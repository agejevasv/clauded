FROM mcr.microsoft.com/devcontainers/universal:2

# The universal image includes: Go, Node, Python, Java, .NET, Ruby, PHP, Rust,
# git, gh, curl, jq, ripgrep, make, gcc, and many other dev tools.

# gosu is needed by the entrypoint for UID/GID remapping with exec semantics.
# Remaining packages are native deps for nih-plug / CLAP audio plugin builds.
RUN rm -f /etc/apt/sources.list.d/yarn.list && \
    apt-get update && apt-get install -y --no-install-recommends \
        gosu \
        libasound2-dev \
        libjack-jackd2-dev \
        libgl-dev \
        libxcb1-dev \
        libxcb-icccm4-dev \
        libxcb-shape0-dev \
        libxcb-xfixes0-dev \
        libxcb-dri2-0-dev \
        libxcb-cursor-dev \
        libxcb-render0-dev \
        libx11-dev \
        libxext-dev \
        libxrandr-dev \
        libxinerama-dev \
        libxcomposite-dev \
        libxrender-dev \
        libxcursor-dev \
        libx11-xcb-dev \
        libxkbcommon-dev \
        libxkbcommon-x11-dev \
        libwayland-dev \
        libfontconfig1-dev \
        libfreetype6-dev && \
    rm -rf /var/lib/apt/lists/*

# Rust toolchain (system-wide so it survives UID/GID remap in entrypoint.sh)
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH
RUN curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path --default-toolchain stable && \
    chmod -R a+w /usr/local/cargo /usr/local/rustup

# Use ripgrep from the image
ENV USE_BUILTIN_RIPGREP=0

# Copy host .gitconfig if provided (optional, see install.sh)
COPY .gitconfi[g] /home/codespace/

# Install Claude CLI at build time so it's baked into the image
USER codespace
RUN curl -fsSL https://claude.ai/install.sh | bash
USER root

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

WORKDIR /workspace
ENV PATH="/home/codespace/.local/bin:$PATH"

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
