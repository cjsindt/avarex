#!/bin/bash
set -euo pipefail

BASEDIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# --- Default Values ---
PARALLEL=false
RAM_MB=1536
TARGETS=()
IMAGE_NAME="avarex-builder"
IMAGE_TAG="latest"
LOGS_DIR="./log"
# ---------------------

usage ()
{
    cat <<EOF
Usage: $0 [-p] [-r <ram_mb>] -t <target> [-t <target> ...] [--dry-run]

Flags:
  -p            Build targets in parallel
  -t <target>   Build target (repeatable)
                apk | ios | linux | macos | web | windows
  -r <ram_mb>   RAM limit in MB (default: auto-detect)
  --dry-run     Show commands without executing
  -h            Show this help page
EOF
    exit 1
}
