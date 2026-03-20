#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DATA_DIR="${SCRIPT_DIR}/data"
readonly LOG_FILE="${DATA_DIR}/deploy.log"

log() {
    local level="$1"
    shift
    printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*" | tee -a "$LOG_FILE"
}

die() {
    log "ERROR" "$*"
    exit 1
}

require() {
    local cmd="$1"
    command -v "$cmd" &>/dev/null || die "Required command not found: $cmd"
}

fibonacci() {
    local n="$1"
    local a=0 b=1 tmp
    local result=()
    for ((i = 0; i < n; i++)); do
        result+=("$a")
        tmp=$((a + b))
        a=$b
        b=$tmp
    done
    echo "${result[*]}"
}

is_prime() {
    local n="$1"
    (( n < 2 )) && return 1
    for ((i = 2; i * i <= n; i++)); do
        (( n % i == 0 )) && return 1
    done
    return 0
}

primes_up_to() {
    local limit="$1"
    local result=()
    for ((i = 2; i <= limit; i++)); do
        is_prime "$i" && result+=("$i")
    done
    echo "${result[*]}"
}

check_health() {
    local service="$1"
    local url="$2"
    local retries="${3:-3}"
    local delay="${4:-2}"

    for ((attempt = 1; attempt <= retries; attempt++)); do
        if curl --silent --fail --max-time 5 "$url" &>/dev/null; then
            log "INFO" "$service is healthy"
            return 0
        fi
        log "WARN" "$service health check failed (attempt $attempt/$retries)"
        sleep "$delay"
    done

    die "$service failed health check after $retries attempts"
}

parse_args() {
    local -n _env="$1"
    local -n _dry_run="$2"
    shift 2

    _env="production"
    _dry_run=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --env)       _env="$2";      shift 2 ;;
            --dry-run)   _dry_run=true;  shift   ;;
            -h|--help)   usage;          exit 0  ;;
            *)           die "Unknown option: $1" ;;
        esac
    done
}

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --env ENV     Target environment (default: production)
  --dry-run     Print actions without executing
  -h, --help    Show this help message
EOF
}

setup_dirs() {
    local dirs=("$@")
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir" || die "Failed to create directory: $dir"
    done
}

deploy() {
    local env="$1"
    local dry_run="$2"

    log "INFO" "Starting deploy to $env (dry_run=$dry_run)"

    local steps=(
        "build:npm run build"
        "test:npm test"
        "migrate:npm run db:migrate"
    )

    for step_def in "${steps[@]}"; do
        local name="${step_def%%:*}"
        local cmd="${step_def#*:}"

        log "INFO" "Step: $name"
        if [[ "$dry_run" == true ]]; then
            log "INFO" "[dry-run] Would run: $cmd"
        else
            eval "$cmd" || die "Step '$name' failed"
        fi
    done

    log "INFO" "Deploy to $env completed successfully"
}

main() {
    local env dry_run
    parse_args env dry_run "$@"

    require "curl"
    require "npm"

    setup_dirs "$DATA_DIR"

    log "INFO" "Fibonacci(8): $(fibonacci 8)"
    log "INFO" "Primes up to 30: $(primes_up_to 30)"

    deploy "$env" "$dry_run"
}

main "$@"
