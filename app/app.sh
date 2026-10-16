#!/usr/bin/env bash
# app.sh - DevOps tool
# Exit codes: 0 = success, 1 = runtime failure, 2 = invalid command/input
set -u

usage() {
    cat <<'EOF'
Usage: app.sh <command> [arguments]

Commands:
  system-info               Display system information
  check-host <host>         Resolve and check a host
  check-port <host> <port>  Check TCP connectivity to host:port (1-65535)
  help                      Show this help message

Exit codes:
  0  success
  1  operational/runtime failure
  2  invalid command or input
EOF
}

cmd_system_info() {
    local os_name="Unknown"
    if [[ -r /etc/os-release ]]; then
        os_name=$(. /etc/os-release && echo "${PRETTY_NAME:-$NAME}")
    fi
    echo "===== System Information ====="
    echo "Hostname:         $(hostname)"
    echo "Current user:     $(whoami)"
    echo "Date/Time:        $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "Operating system: $os_name"
    echo "Kernel version:   $(uname -r)"
    echo "Architecture:     $(uname -m)"
    echo "CPU cores:        $(nproc 2>/dev/null || echo unknown)"
    echo
    echo "----- Memory -----"
    if command -v free >/dev/null 2>&1; then
        free -h
    else
        grep -E 'MemTotal|MemAvailable' /proc/meminfo
    fi
}

valid_host() {
    [[ "$1" =~ ^[A-Za-z0-9]([A-Za-z0-9.:-]*[A-Za-z0-9])?$ ]]
}

valid_port() {
    [[ "$1" =~ ^[0-9]{1,5}$ ]] && (( 10#$1 >= 1 && 10#$1 <= 65535 ))
}

cmd_check_host() {
    local host="${1:-}"
    if [[ -z "$host" ]]; then
        echo "Error: check-host requires a host" >&2
        usage >&2
        return 2
    fi
    if ! valid_host "$host"; then
        echo "Error: invalid host: $host" >&2
        return 2
    fi

    local resolved
    resolved=$(getent ahosts "$host" 2>/dev/null | awk 'NR==1 {print $1}')
    if [[ -z "$resolved" ]]; then
        echo "Error: could not resolve host: $host" >&2
        return 1
    fi
    echo "Host $host resolves to $resolved"
}

cmd_check_port() {
    local host="${1:-}" port="${2:-}"
    if [[ -z "$host" || -z "$port" ]]; then
        echo "Error: check-port requires <host> and <port>" >&2
        usage >&2
        return 2
    fi
    if ! valid_host "$host"; then
        echo "Error: invalid host: $host" >&2
        return 2
    fi
    if ! valid_port "$port"; then
        echo "Error: port must be an integer from 1 to 65535" >&2
        return 2
    fi

    port=$((10#$port))
    if timeout 3 bash -c "exec 3<>/dev/tcp/$host/$port" 2>/dev/null; then
        echo "Port $port on $host is open"
    else
        echo "Port $port on $host is closed or unreachable" >&2
        return 1
    fi
}

main() {
    if [[ $# -lt 1 ]]; then
        echo "Error: no command given" >&2
        usage >&2
        return 2
    fi

    local command="$1"
    shift

    case "$command" in
        system-info) cmd_system_info ;;
        check-host)  cmd_check_host "$@" ;;
        check-port)  cmd_check_port "$@" ;;
        help|-h|--help) usage ;;
        *)
            echo "Error: unknown command: $command" >&2
            usage >&2
            return 2
            ;;
    esac
}

main "$@"
exit $?
