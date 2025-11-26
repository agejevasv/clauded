# clauded (Claude Code Docker Container)

A Docker-based wrapper for running [Claude Code](https://claude.com/product/claude-code) in an isolated, containerized environment. This provides a secure and reproducible way to run Claude AI's coding assistant without modifying your host system.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [How It Works](#how-it-works)
- [Instance Management](#instance-management)
- [Configuration](#configuration)
- [Uninstallation](#uninstallation)
- [Security Considerations](#security-considerations)
- [Troubleshooting](#troubleshooting)
- [Native vs Containerized Performance](#native-vs-containerized-performance)
- [License](#license)

## Features

- **Isolated Environment**: Runs Claude Code in a Docker container with minimal Alpine Linux base
- **Sandbox Mode**: Option to run without mounting host directories for maximum isolation
- **Security Hardening**:
  - Automatic tmpfs masking of sensitive directories (`.env`, `.ssh`, credentials, etc.)
  - No new privileges flag for enhanced container security
  - User permission mapping between host and container
- **Persistent Configuration**: Claude Code settings preserved in a Docker volume
- **Instance Management**: Handles multiple instances with attach/replace options
- **Reasonably fast**: [the containerized version is slim and reasonably fast](#native-vs-containerized-performance)

## Prerequisites

- Docker installed and running
- `sudo` access for installation (copies script to `/usr/local/bin`)
- Bash shell

## Installation

Clone the repository and run the installation script:

```bash
git clone https://github.com/agejevasv/clauded.git
cd clauded
./install.sh
```

The installation script will:
1. Build the Docker image (`clauded:latest`)
2. Copy the `clauded` command to `/usr/local/bin`
3. Trigger native Claude Code client installation in the container

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
4. **Permission Mapping**: Maps your host UID/GID to the container user

### Directories Masked (Non-Sandbox Mode)

When running with a mounted directory, these subdirectories are automatically masked with tmpfs if they exist:
- `.env`
- `.ssh`
- `config/credentials`
- `config/secrets`
- `credentials`
- `secrets`
- `node_modules`
- `tmp`

## Instance Management

If you try to start `clauded` while another instance is running, you'll see options to:

1. **Attach to running container** - Connect to the existing instance (uses existing configuration, meaning new directory won't be mounted)
2. **Stop and restart** - Stop the previous instance and start fresh with new configuration
3. **Exit** - Cancel the operation

## Configuration

Claude Code configuration is stored in a persistent Docker volume named `clauded-volume`. This preserves your settings, authentication, and preferences across container restarts.

To reset configuration, remove the volume:

```bash
docker volume rm clauded-volume
```

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

## Native vs Containerized Performance

Based on my smoke tests, the containerized version has minimal time overhead compared to running Claude Code natively, e.g.:

### Native time
```bash
time claude --version

2.0.55 (Claude Code)
claude --version  0.54s user 0.29s system 157% cpu 0.527 total
```
### Container time
```bash
time clauded --version

🐳 Starting Claude Code...
⚙️ Mode: mounted (/home/me/clauded)
2.0.55 (Claude Code)
Container stopped.
clauded --version  0.04s user 0.06s system 9% cpu 1.016 total
```
Interestingly, containerized version seems to use less memory:

### Native top
```bash
top -p $(pgrep -d',' claude)

    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
 108147   me      20   0   71.0g 436.0m  49.2m S   1.0   1.4   0:05.05 claude
```
### Container top
```bash
top -p $(pgrep -d',' 'docker|clauded')

    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
    964 root      20   0 2243.3m  85.7m  50.1m S   0.0   0.3   0:05.60 dockerd
 109131   me      20   0   10.0m   7.3m   6.9m S   0.0   0.0   0:00.00 clauded
 109169   me      20   0 1700.4m  30.4m  17.4m S   0.0   0.1   0:00.05 docker
```
## License

MIT License - See LICENSE file for details
