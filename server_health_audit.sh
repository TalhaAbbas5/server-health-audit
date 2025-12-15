#!/bin/bash
set -euo pipefail


CONFIG_FILE="$(pwd)/configs/server_audit.conf"

# Load config
# Check if config file exists
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "ERROR: Config file not found at $CONFIG_FILE"
    exit 1
fi

HOSTNAME=$(hostname)

# Output directory & file
#OUT_DIR="$(pwd)/reports"
#mkdir -p "$OUT_DIR"
#REPORT_FILE="$OUT_DIR/server_report_$(date +%F_%H).txt"
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
echo $BASE_DIR
PROM_DIR="$BASE_DIR/prom_files"
mkdir -p "$PROM_DIR"
REPORT_DIR="$BASE_DIR/reports"

mkdir -p "$REPORT_DIR"
REPORT_FILE="$REPORT_DIR/server_report_$(date +%F_%H).txt"


CPU_PROM="$PROM_DIR/cpu.prom"
MEM_PROM="$PROM_DIR/mem.prom"
DISK_PROM="$PROM_DIR/disk.prom"
FAILED_PROM="$PROM_DIR/failed.prom"


# -----------------------------
# Function: Append to report
# -----------------------------
append() {
  mkdir -p "$(dirname "$REPORT_FILE")"  # ensure directory exists before every write
  echo -e "$1" >> "$REPORT_FILE"
}

# -----------------------------
# Log Rotation: Keep last 5 reports
# -----------------------------
rotate_logs() {
  MAX_REPORTS=5
  mkdir -p "$REPORT_DIR"            # ensure directory exists
  cd "$REPORT_DIR" || return
  FILES=$(ls -1t server_report_*.txt 2>/dev/null)
  if [ -n "$FILES" ]; then
    echo "$FILES" | tail -n +$((MAX_REPORTS+1)) | xargs -r rm
  fi
}

# -----------------------------
# Function: Send Email Alert
# -----------------------------
send_alert() {
  SUBJECT="$1 on $(hostname -s)"
  BODY="Server: $(hostname -f)\n$2"
  echo -e "$BODY" | mail -s "$SUBJECT" -r "Server Monitor <alerts@circles.co>"  "$EMAIL"
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
    local cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
    append "CPU Usage: ${cpu}%"
    echo "CPU{type:\"CPU_USAGE\",host:\"$HOSTNAME\"}" $cpu > "$CPU_PROM"
    if (( $(echo "$cpu > $CPU_THRESHOLD" | bc -l) )); then
        send_alert "CRITICAL: CPU High" "CPU usage is ${cpu}%"
    fi
}

# -----------------------------
# Memory Usage
# -----------------------------
check_memory() {
    local mem=$(free | awk '/Mem:/ {printf "%.1f", $3/$2*100}')
    append "Memory Usage: ${mem}%"
        echo "Memory{type:\"Memory_USAGE\",host:\"$HOSTNAME\"}" $mem > "$MEM_PROM"
    if (( $(echo "$mem > $MEM_THRESHOLD" | bc -l) )); then
        send_alert "CRITICAL: Memory High" "Memory usage is ${mem}%"
    fi
}

# -----------------------------
# Disk Usage
# -----------------------------
check_disk() {
    >$DISK_PROM
    df -h | tail -n +2 | while read line; do
        mount=$(echo $line | awk '{print $6}')
        usage=$(echo $line | awk '{print $5}' | sed 's/%//')
        append "disk_usage $mount" "$usage"
        echo "Disk_usage{type:\"Disk_usage\",host:\"$HOSTNAME\",Mount_point=\"$mount\"}" $usage >> "$DISK_PROM"
        if [ "$usage" -ge "$DISK_THRESHOLD" ]; then
            send_alert "CRITICAL: Disk Full on $mount" "$usage% used"
        fi
    done
}

# -----------------------------
# Top 5 CPU Processes
# -----------------------------
top_processes() {
    ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 6 | tail -n 5 | while read pid comm cpu mem; do
        append "top_process_${comm}_cpu" "$cpu"
        append "top_process_${comm}_mem" "$mem"
    done
}

# -----------------------------
# Failed SSH logins and Brute-force detection
# -----------------------------
failed_ssh() {
    local failed=$(sudo grep "authentication failure" "$SECURE_LOG" | grep -v "COMMAND" | wc -l)
    append "failed_ssh_logins" "$failed"
    echo "Failed_SSH{type:\"Failed_SSH\",host:\"$HOSTNAME\"}" $failed > "$FAILED_PROM"
    echo "$failed"
    if [ "$failed" -ge "$LOGIN_THRESHOLD" ]; then
     send_alert "CRITICAL: Failed SSH logins " "Count :$failed check logs : /var/log/secure"
    fi

}

# -----------------------------
# Cron job errors
# -----------------------------
cron_errors() {
    local errors=$(sudo grep "error" "$CRON_LOG" | wc -l)
    append "cron_errors" "$errors"
}

# -----------------------------
# Critical Port Monitoring
# -----------------------------
check_ports() {
    for entry in "${PORTS[@]}"; do
        port="${entry%%:*}"
        proto="${entry##*:}"
        echo "$port $proto"
        value=`ss -tuln | grep -q "$proto.*:$port "`
        echo $value
        if ss -tuln | grep -q "$proto.*:$port "; then
            echo "Port $port listening"
            append "port_${port}_${proto} is listening"
        else
            echo "Port $port not listening"
            append "port_${port}_${proto} is not listening"
            send_alert "CRITICAL: Port $port/$proto Down" "Port $port ($proto) not listening"
        fi

done
}

rotate_logs
print_header
check_cpu
check_memory
check_disk
top_processes
failed_ssh
cron_errors
check_ports

