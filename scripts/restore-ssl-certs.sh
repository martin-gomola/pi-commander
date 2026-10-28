#!/usr/bin/env bash
# SSL certificate restore adapter for pi-commander.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/pi-commander" restore-ssl "${1:-}"
