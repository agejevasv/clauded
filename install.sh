#!/bin/bash
# Installation script for Claude Code Docker container

set -e

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="clauded:latest"
INSTALL_PATH="/usr/local/bin/clauded"

FORCE_BUILD=false
for arg in "$@"; do
  case $arg in
    --force)
      FORCE_BUILD=true
      shift
      ;;
    *)
      echo -e "${RED}Unknown option: $arg${NC}"
      echo "Usage: $0 [--force]"
      exit 1
      ;;
  esac
done

echo -e "${GREEN}Installing Claude Code Docker container...${NC}"

BUILD_ARGS="-t ${IMAGE_NAME}"
if [ "$FORCE_BUILD" = true ]; then
  echo -e "${YELLOW}Building Docker image with --no-cache...${NC}"
  BUILD_ARGS="${BUILD_ARGS} --no-cache"
else
  echo -e "${YELLOW}Building Docker image...${NC}"
fi

if ! docker build ${BUILD_ARGS} "${SCRIPT_DIR}"; then
    echo -e "${RED}Error: Docker build failed${NC}" >&2
    exit 1
fi
echo -e "${GREEN}Docker image built successfully!${NC}"

echo -e "${YELLOW}Copying clauded to ${INSTALL_PATH}${NC}"
if ! sudo cp "${SCRIPT_DIR}/clauded" "${INSTALL_PATH}"; then
    echo -e "${RED}Error: Failed to copy clauded to ${INSTALL_PATH}${NC}" >&2
    echo -e "${YELLOW}You may need sudo permissions${NC}" >&2
    exit 1
fi

if ! sudo chmod 755 "${INSTALL_PATH}"; then
    echo -e "${RED}Error: Failed to set permissions on ${INSTALL_PATH}${NC}" >&2
    exit 1
fi

if clauded -s --version; then
  echo -e "${GREEN}Installation complete, run: clauded${NC}"
else
  echo -e "${RED}Error: Claude Code installation failed${NC}" >&2
fi
