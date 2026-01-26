FROM debian:bookworm-slim

# Packages:
#  - bash           Required for entrypoint script execution
#  - ca-certificates Ensures HTTPS connections work properly
#  - curl           Downloads Claude CLI installer at runtime
#  - diffutils      Standard diff/cmp tools used by Claude Code
#  - gcc            C compiler for building native extensions
#  - gh             GitHub CLI for PR/issue management
#  - git            Version control — core to Claude Code workflows
#  - git-lfs        Git Large File Storage support
#  - gosu           Safer alternative to sudo for privilege dropping
#  - gzip           Archive extraction
#  - jq             JSON processing for scripts and tool output
#  - less           Pager for git log, diff, etc.
#  - libc6-dev      C library headers for compiling native extensions
#  - make           Build automation tool
#  - nodejs         JavaScript/TypeScript runtime
#  - npm            Node.js package manager
#  - openssh-client SSH client for git+ssh and remote access
#  - patch          Apply patch files
#  - python3        Python runtime
#  - python3-pip    Python package manager
#  - ripgrep        Fast search tool required by Claude Code
#  - tar            Archive extraction
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    diffutils \
    gcc \
    gh \
    git \
    git-lfs \
    gosu \
    gzip \
    jq \
    less \
    libc6-dev \
    make \
    nodejs \
    npm \
    openssh-client \
    patch \
    python3 \
    python3-pip \
    ripgrep \
    tar \
    && rm -rf /var/lib/apt/lists/*

# Use ripgrep from apt
ENV USE_BUILTIN_RIPGREP=0

RUN groupadd -g 1000 claude && useradd -m -u 1000 -g claude claude

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh
COPY settings.json /home/claude/.claude/settings.json
COPY .gitconfi[g] /home/claude/


WORKDIR /workspace

ENV PATH="/home/claude/.local/bin:$PATH"

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
