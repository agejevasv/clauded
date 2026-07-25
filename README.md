# clauded (Claude Code Docker Container)

A Docker-based wrapper for running [Claude Code](https://claude.com/product/claude-code) in an isolated, containerized environment.

## Installation

### Prerequisites

- Docker installed and running
- `sudo` access for installation (copies script to `/usr/local/bin`)
- Bash shell

Clone the repository and run the installation script:

```bash
git clone https://github.com/agejevasv/clauded.git
cd clauded
./install.sh
```

The installation script will:
1. Build the Docker image (`clauded:latest`) based on [`devcontainers/universal:2`](https://github.com/devcontainers/images/tree/main/src/universal) which includes Go, Node, Python, Java, .NET, Ruby, PHP, Rust, and common dev tools
2. Copy the `clauded` command to `/usr/local/bin`
3. Install Claude Code CLI into the image

To rebuild the image without cache:

```bash
./install.sh --force
```

## Usage

### Basic Usage

Run Claude Code in your current directory:

```bash
clauded
```

This mounts your current working directory to `/workspace` in the container and starts Claude Code.

### Sandbox Mode

Run in sandbox mode (no host directory mounted):

```bash
clauded --sandbox
# or
clauded -s
```

### Opening a Shell

Drop into a bash shell inside the **already-running** container:

```bash
clauded shell
# target a specific profile's container:
clauded --profile=work shell
# run a one-off command instead of an interactive shell:
clauded shell -c "uv tool install ruff"
```

The shell runs as the `codespace` user in `/workspace`. Note that only
`/workspace` (your mounted directory) and `/home/codespace` (the persistent
volume) survive a restart — because the container runs with `--rm`, anything
installed elsewhere (e.g. `apt` packages, `/usr`, `/etc`) is lost when it stops.
For permanent system-wide changes, edit the `Dockerfile` and rebuild with
`./install.sh`.

### Exposing Ports

By default no ports are published — the container uses bridge networking with
nothing forwarded. To reach a server running inside the container from the host,
publish its port at start time with `--port` (alias: `--publish`):

```bash
# server in the container listens on 4242 -> reachable at localhost:4242
clauded --port 4242

# map to a different host port (host:container)
clauded --port 8080:4242

# bind to a specific host interface, or publish several ports
clauded --port 127.0.0.1:4242:4242 --port 9229
```

A bare number (`--port 4242`) is expanded to `4242:4242`; anything more specific
is passed straight to `docker run -p`. The flag is repeatable.

> Ports must be published when the container starts. If an instance is already
> running, attaching to it (option 1) cannot add mappings — restart it (option 2)
> for new `--port` values to take effect.

### Named Profiles

Run multiple isolated Claude Code instances side-by-side using `--profile`:

```bash
clauded --profile=work
clauded --profile=chat
```

Each profile gets:

- Its own container (`clauded-container-<name>`) — multiple profiles can run in parallel without triggering the instance-management prompt.
- Its own persistent volume (`clauded-volume-<name>`) — settings, selected model, and todos are independent. Changing the model in one profile does **not** affect any other profile. (Memory and session transcripts are the exception: they live in the project directory, so profiles working on the same project share them — see [Project Memory and Transcripts](#project-memory-and-transcripts).)

If the default `clauded-volume` already exists when a new profile is created, the profile volume is seeded from it, so any existing OAuth credentials carry over and you don't need to log in again. If the default volume doesn't exist yet, the profile starts empty and Claude Code will prompt for login on first run, just like a fresh install. After creation, each profile is fully independent — re-authenticating in one profile does not propagate to the others.

### Passing Arguments to Claude Code

All arguments (except `--sandbox`/`-s`) are passed directly to the Claude Code CLI:

```bash
# Show version
clauded --version

# Start with specific model
clauded --model sonnet

# Combine with sandbox mode
clauded -s --help
```

## How It Works

1. **Container Creation**: Creates a persistent Docker volume for Claude Code configuration
2. **Directory Mounting**: Mounts your current directory (unless in sandbox mode)
3. **Security Masking**: Automatically creates tmpfs overlays for sensitive directories to prevent access

### Directories Masked (Non-Sandbox Mode)

When running with a mounted directory, these subdirectories are automatically masked with tmpfs if they exist:
- `.env`
- `.ssh`
- `config/credentials`
- `config/secrets`
- `credentials`
- `secrets`

## Instance Management

If you try to start `clauded` while another instance is running, you'll see options to:

1. **Attach to running container** - Connect to the existing instance (uses existing configuration, meaning new directory won't be mounted)
2. **Stop and restart** - Stop the previous instance and start fresh with new configuration
3. **Exit** - Cancel the operation

## Configuration

Claude Code configuration is stored in a persistent Docker volume named `clauded-volume`, mounted at `/home/codespace`. This preserves your settings, authentication, and preferences across container restarts.

To reset configuration, remove the volume:

```bash
docker volume rm clauded-volume
```

### Project Memory and Transcripts

Claude Code stores per-project state — its memory files and session transcripts —
under `~/.claude/projects/<slug>`, where the slug is derived from the working
directory. Since `clauded` always mounts your project at `/workspace`, that slug
is always `-workspace`, so **every** host project would otherwise share a single
store inside `clauded-volume`.

To avoid that, non-sandbox runs bind two directories back into your project:

| Host path | Contents |
| --- | --- |
| `.claude/memory/` | Memory files and the `MEMORY.md` index |
| `.claude/transcripts/` | Session transcripts (`*.jsonl`) and per-session state |

Consequences worth knowing:

- Memory and history follow the code — clone the repo elsewhere and they come with it.
- `--continue` / `--resume` now list only *this* project's sessions instead of
  every project you've ever opened.
- Memory files are plain Markdown, so they show up in `git status` and can be
  reviewed in diffs or shared with the repo. Add `.claude/memory/` to
  `.gitignore` if you'd rather keep them local.
- Transcripts get large (hundreds of MB is normal). Ignore them:

  ```
  .claude/transcripts/
  ```

- Both are shared across profiles, since they belong to the project rather than
  to the profile.
- Sandbox mode (`--sandbox`) has no host directory, so it keeps using the volume.

Existing state from before this change is still in the volume, just shadowed by
the mounts. To retrieve it:

```bash
docker run --rm -v clauded-volume:/v alpine ls /v/.claude/projects/-workspace
```

### GitHub Token

To enable `gh` CLI access and HTTPS-based git operations inside the container, provide a `GITHUB_TOKEN`. The token is used to authenticate the `gh` CLI and to automatically rewrite SSH git URLs (`git@github.com:`) to HTTPS, so cloning, pushing, and PR workflows work without SSH keys.

You can provide the token in two ways:

**Option 1 — Environment variable** (recommended for CI or ephemeral use):

```bash
export GITHUB_TOKEN="ghp_..."
clauded
```

**Option 2 — `.env` file** (recommended for personal use):

Create a `.env` file in the directory where you run `clauded`:

```bash
GITHUB_TOKEN="ghp_..."
```

The `.env` file is automatically sourced before the container starts. It is also masked inside the container via a tmpfs overlay, so Claude Code cannot read the file's contents.

> **Tip:** You can create a fine-grained personal access token at https://github.com/settings/tokens with only the repository permissions you need.

## Uninstallation

Remove the installed command:

```bash
sudo rm /usr/local/bin/clauded
```

Remove the Docker image:

```bash
docker rmi clauded:latest
```

Remove the configuration volume:

```bash
docker volume rm clauded-volume
```

## Security Considerations

- The container runs with `no-new-privileges` flag to prevent privilege escalation
- Sensitive directories are masked by default when mounting host directories
- Claude CLI is downloaded from the official source (`https://claude.ai/install.sh`)
- The entrypoint validates UID/GID inputs to prevent injection attacks

## Troubleshooting

**Docker image not found**: Run `./install.sh` to build the image

**Permission denied**: Ensure Docker is running and your user has Docker permissions

**Installation fails**: Try `./install.sh --force` to rebuild without cache

## License

MIT License - See LICENSE file for details
