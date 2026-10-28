#!/usr/bin/env bash
# Automated full backup adapter for pi-commander.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/pi-commander" backup-full
