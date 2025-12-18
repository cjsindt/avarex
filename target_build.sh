#!/bin/bash
set -euo pipefail

# CHANGE TO YOUR SYSTEM'S CONTAINER ENGINE
# (podman or docker)
CONTAINER_ENGINE="docker"

# ----------------------
BASEDIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Default Values
CONTAINER="flutter-builder"
DRY_RUN=false
IMAGE="avarex-builder:latest"
LOGS_DIR="./log"
PARALLEL=false
RAM_MB=1536
TARGETS=()


usage ()
{
    cat <<EOF
Usage: $0 -t <target> [-t <target> ...] [-p] [-r <ram_mb>] [-i <image>] [-c <container>] [--dry-run]

Flags:
  -t <target>       Build target (repeatable)
                    apk | ios | linux | macos | snap | web | windows
  -p                Build targets in parallel
                    (Requires more RAM)
  -r <ram_mb>       Gradle RAM limit in MB (default: 1536)
  -i <image>        Use alternate image (default: avarex-builder:latest)
  -c <container>    Rename build container (default: flutter-builder)
  --dry-run         Show commands without executing
  -h                Show this help page
EOF
    exit 1
}

ensure_container ()
{
    if ! $CONTAINER_ENGINE ps -a --format '{{.Names}}' | grep -q "^$CONTAINER\$"; then
        echo -e "\033[1;34mStarting container \033[0m$CONTAINER \033[1;34mfrom \033[0m$IMAGE\033[0m"
        "$CONTAINER_ENGINE" run -dit \
            --name "$CONTAINER" \
            -v "$BASEDIR":"/workspace" \
            -w "/workspace" \
            "$IMAGE" > /dev/null
    fi
}

# Spinny for Running Containers
spinny()
{
    local pid=$1
    local target=$2
    local delay=0.1
    local spinstr='|/-\'
    local color="\033[1;34m"   # blue
    local reset="\033[0m"

    while kill -0 "$pid" 2>/dev/null; do
        for i in $(seq 0 3); do
            printf "\r%b%s:%b [%c] Running..." "$color" "$target" "$reset" "${spinstr:$i:1}" 
            sleep $delay
        done
    done

    printf "\r%b%s:%b                   " "$color" "$target" "$reset"

    if [ -f "$LOGS_DIR/$target.exit" ]; then
        exit_code=$(cat "$LOGS_DIR/$target.exit")
        if [ "$exit_code" -eq 0 ]; then
            printf "\r\033[1;32m%s:\033[0m [DONE]\n" "$target"
        else
            printf "\r\033[1;31m%s:\033[0m [FAILED] See $LOGS_DIR/$target.log for more info\n" "$target"
        fi
    fi
}

# Runs a Single Build
run_build ()
{
    local target="$1"
    local log_file="$LOGS_DIR/$target.log"
    local exit_file="$LOGS_DIR/$target.exit"
    local cmd
    cmd=$(build_cmd "$target")

    rm -f "$exit_file"

    "$CONTAINER_ENGINE" exec \
        -e "GRADLE_OPTS=-Xmx${RAM_MB}m -XX:MaxMetaspaceSize=512m" \
        -e "JAVA_TOOL_OPTIONS=-Xmx${RAM_MB}m" \
        -e "FLUTTER_MAX_WORKERS=1" \
        "$CONTAINER" \
        bash -lc "$cmd ; echo \$? > $exit_file" \
        >"$log_file" 2>&1 &

    local pid=$!
    echo "$pid"
}

# Parse Flags
while [[ $# -gt 0 ]]; do
    case "$1" in
        -p) PARALLEL=true; shift ;;
        -d) IMAGE="$2"; shift 2 ;;
        -t) TARGETS+=("$2"); shift 2 ;;
        -r) RAM_MB="$2"; shift 2 ;;
        -i) IMAGE="$2"; shift 2 ;;
        -c) CONTAINER="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        -h) usage ;;
        *) echo "Unknown argument: $1"; usage ;;
    esac
done

[[ ${#TARGETS[@]} -eq 0 ]] && usage
mkdir -p "$LOGS_DIR"
ensure_container

# Converts Build Argument to Flutter Build Command
build_cmd ()
{
    case "$1" in
        apk)        echo "flutter build apk -v -Dorg.gradle.caching=true -Porg.gradle.workers.max=1 -Porg.gradle.parallel=false --split-debug-info=build/debug-info" ;;
        ios)        echo "flutter build ios -v" ;;
        linux)      echo "flutter build linux -v" ;;
        macos)      echo "flutter build macos -v" ;;
        snap)       echo "flutter build snap -v" ;;
        web)        echo "flutter build web -v" ;;
        windows)    echo "flutter build windows -v" ;;
        *)          echo "Unknown target: $1"; usage; exit 1 ;;
    esac
}

# Run Builds 
if [[ "$PARALLEL" == false ]]; then
    for target in "${TARGETS[@]}"; do
        if [[ "$DRY_RUN" == "true" ]]; then
            echo -e "\033[1;34m[DRY-RUN] $target: \033[0m$(build_cmd $target)\n"
        else 
            pid=$(run_build "$target")
            spinny "$pid" "$target"
            wait || echo -e "\033[1;31m$target failed. Check $LOGS_DIR/$target.log\033[0m"
        fi
    done
    exit 0
fi
