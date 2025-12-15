#!/bin/bash
set -euo pipefail

CONFIG_FILE="$(pwd)/configs/server_audit.conf"

# Load config
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
else
    echo "ERROR: Config file not found at $CONFIG_FILE"
    exit 1
fi

HOSTNAME=$(hostname)

# Output directories & files
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
PROM_DIR="$BASE_DIR/prom_files"
REPORT_DIR="$BASE_DIR/reports"

mkdir -p "$PROM_DIR" "$REPORT_DIR"

REPORT_FILE="$REPORT_DIR/server_report_$(date +%F_%H).txt"
CPU_PROM="$PROM_DIR/cpu.prom"
MEM_PROM="$PROM_DIR/mem.prom"
DISK_PROM="$PROM_DIR/disk.prom"
FAILED_PROM="$PROM_DIR/failed.prom"

# -----------------------------
# Function: Append to report
# -----------------------------
append() {
    mkdir -p "$(dirname "$REPORT_FILE")"
    echo -e "$1" >> "$REPORT_FILE"
}

# -----------------------------
# Log Rotation: Keep last 5 reports
# -----------------------------
rotate_logs() {
    mkdir -p "$REPORT_DIR"
    cd "$REPORT_DIR" || return
    files=( $(ls -1t server_report_*.txt 2>/dev/null) )
    if (( ${#files[@]} > MAX_REPORTS )); then
        for old_file in "${files[@]:MAX_REPORTS}"; do
            rm -f "$old_file"
        done
    fi
}

# -----------------------------
# Function: Send Email Alert
# -----------------------------
send_alert() {
    local subject body
    subject="$1 on $(hostname -s)"
    body="Server: $(hostname -f)\n$2"
    echo -e "$body" | mail -s "$subject" -r "Server Monitor <alerts@circles.co>" "$EMAIL"
}

# -----------------------------
# Function: Header
# -----------------------------
print_header() {
    append "----- Server Health Report -----"
    append "Date: $(date)"
    append ""
}

# -----------------------------
# CPU Usage
# -----------------------------
check_cpu() {
    local cpu
    cpu=$(top -bn1 | awk '/Cpu\(s\)/ {print 100 - $8}')
    append "CPU Usage: ${cpu}%"
    echo "CPU{type:\"CPU_USAGE\",host:\"$HOSTNAME\"} $cpu" > "$CPU_PROM"
    if (( $(echo "$cpu > $CPU_THRESHOLD" | bc -l) )); then
        send_alert "CRITICAL: CPU High" "CPU usage is ${cpu}%"
    fi
}

# -----------------------------
# Memory Usage
# -----------------------------
check_memory() {
    local mem
    mem=$(free | awk '/Mem:/ {printf "%.1f", $3/$2*100}')
    append "Memory Usage: ${mem}%"
    echo "Memory{type:\"Memory_USAGE\",host:\"$HOSTNAME\"} $mem" > "$MEM_PROM"
    if (( $(echo "$mem > $MEM_THRESHOLD" | bc -l) )); then
        send_alert "CRITICAL: Memory High" "Memory usage is ${mem}%"
    fi
}

# -----------------------------
# Disk Usage
# -----------------------------
check_disk() {
    : >"$DISK_PROM"
    df -h | tail -n +2 | while read -r filesystem size used avail usep mount; do
        usage="${usep%\%}"  # remove % symbol
        append "disk_usage $mount $usage"
        echo "Disk_usage{type:\"Disk_usage\",host:\"$HOSTNAME\",Mount_point=\"$mount\"} $usage" >> "$DISK_PROM"
        if [ "$usage" -ge "$DISK_THRESHOLD" ]; then
            send_alert "CRITICAL: Disk Full on $mount" "$usage% used"
        fi
    done
}

# -----------------------------
# Top 5 CPU Processes
# -----------------------------
top_processes() {
    ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 6 | tail -n 5 | while read -r _ comm cpu mem; do
        append "top_process_${comm}_cpu $cpu"
        append "top_process_${comm}_mem $mem"
    done
}

# -----------------------------
# Failed SSH logins and Brute-force detection
# -----------------------------
failed_ssh() {
    local failed
    failed=$(sudo grep "authentication failure" "$SECURE_LOG" | grep -cv "COMMAND")
    append "failed_ssh_logins $failed"
    echo "Failed_SSH{type:\"Failed_SSH\",host:\"$HOSTNAME\"} $failed" > "$FAILED_PROM"
    if [ "$failed" -ge "$LOGIN_THRESHOLD" ]; then
        send_alert "CRITICAL: Failed SSH logins" "Count: $failed check logs: $SECURE_LOG"
    fi
}

# -----------------------------
# Cron job errors
# -----------------------------
cron_errors() {
    local errors
    errors=$(sudo grep "error" "$CRON_LOG" | wc -l)
    append "cron_errors $errors"
}

# -----------------------------
# Critical Port Monitoring
# -----------------------------
check_ports() {
    local port proto
    for entry in "${PORTS[@]}"; do
        port="${entry%%:*}"
        proto="${entry##*:}"
        if ss -tuln | grep -q "${proto}.*:${port}"; then
            append "port_${port}_${proto} is listening"
        else
            append "port_${port}_${proto} is not listening"
            send_alert "CRITICAL: Port $port/$proto Down" "Port $port ($proto) not listening"
        fi
    done
}

# -----------------------------
# Execute Checks
# -----------------------------
rotate_logs
print_header
check_cpu
check_memory
check_disk
top_processes
failed_ssh
cron_errors
check_ports


