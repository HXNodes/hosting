#!/bin/bash

# =============================================================================
# hxnodes System Monitoring Script
# =============================================================================
# This script monitors system health, resource usage, and sends alerts
# Run this script via cron for continuous monitoring
# =============================================================================

set -e

# Configuration
LOG_FILE="/var/log/hxnodes/monitoring.log"
ALERT_EMAIL="admin@yourdomain.com"
DISCORD_WEBHOOK="https://discord.com/api/webhooks/your-webhook-url"
SLACK_WEBHOOK="https://hooks.slack.com/services/your-webhook-url"

# Thresholds
CPU_THRESHOLD=80
MEMORY_THRESHOLD=85
DISK_THRESHOLD=90
LOAD_THRESHOLD=5

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_info() {
    log "INFO: $1"
}

log_warning() {
    log "WARNING: $1"
    echo -e "${YELLOW}WARNING: $1${NC}"
}

log_error() {
    log "ERROR: $1"
    echo -e "${RED}ERROR: $1${NC}"
}

log_success() {
    log "SUCCESS: $1"
    echo -e "${GREEN}SUCCESS: $1${NC}"
}

# =============================================================================
# ALERT FUNCTIONS
# =============================================================================

send_email_alert() {
    local subject="$1"
    local message="$2"
    
    if command -v mail &> /dev/null; then
        echo "$message" | mail -s "hxnodes Alert: $subject" "$ALERT_EMAIL"
        log_info "Email alert sent: $subject"
    else
        log_warning "mail command not available, skipping email alert"
    fi
}

send_discord_alert() {
    local message="$1"
    
    if [ -n "$DISCORD_WEBHOOK" ]; then
        curl -H "Content-Type: application/json" \
             -X POST \
             -d "{\"content\":\"$message\"}" \
             "$DISCORD_WEBHOOK" > /dev/null 2>&1
        log_info "Discord alert sent"
    fi
}

send_slack_alert() {
    local message="$1"
    
    if [ -n "$SLACK_WEBHOOK" ]; then
        curl -X POST \
             -H 'Content-type: application/json' \
             --data "{\"text\":\"$message\"}" \
             "$SLACK_WEBHOOK" > /dev/null 2>&1
        log_info "Slack alert sent"
    fi
}

send_alert() {
    local level="$1"
    local subject="$2"
    local message="$3"
    
    case $level in
        "critical")
            send_email_alert "$subject" "$message"
            send_discord_alert "🚨 CRITICAL: $subject - $message"
            send_slack_alert "🚨 CRITICAL: $subject - $message"
            ;;
        "warning")
            send_email_alert "$subject" "$message"
            send_discord_alert "⚠️ WARNING: $subject - $message"
            ;;
        "info")
            log_info "$subject: $message"
            ;;
    esac
}

# =============================================================================
# SYSTEM CHECKS
# =============================================================================

check_cpu_usage() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    local cpu_usage_int=${cpu_usage%.*}
    
    log_info "CPU Usage: ${cpu_usage}%"
    
    if [ "$cpu_usage_int" -gt "$CPU_THRESHOLD" ]; then
        send_alert "warning" "High CPU Usage" "CPU usage is ${cpu_usage}% (threshold: ${CPU_THRESHOLD}%)"
        return 1
    fi
    
    return 0
}

check_memory_usage() {
    local mem_info=$(free | grep Mem)
    local mem_total=$(echo $mem_info | awk '{print $2}')
    local mem_used=$(echo $mem_info | awk '{print $3}')
    local mem_usage=$((mem_used * 100 / mem_total))
    
    log_info "Memory Usage: ${mem_usage}%"
    
    if [ "$mem_usage" -gt "$MEMORY_THRESHOLD" ]; then
        send_alert "warning" "High Memory Usage" "Memory usage is ${mem_usage}% (threshold: ${MEMORY_THRESHOLD}%)"
        return 1
    fi
    
    return 0
}

check_disk_usage() {
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | cut -d'%' -f1)
    
    log_info "Disk Usage: ${disk_usage}%"
    
    if [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
        send_alert "critical" "High Disk Usage" "Disk usage is ${disk_usage}% (threshold: ${DISK_THRESHOLD}%)"
        return 1
    fi
    
    return 0
}

check_load_average() {
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | cut -d',' -f1)
    local load_avg_int=${load_avg%.*}
    
    log_info "Load Average: ${load_avg}"
    
    if [ "$load_avg_int" -gt "$LOAD_THRESHOLD" ]; then
        send_alert "warning" "High Load Average" "Load average is ${load_avg} (threshold: ${LOAD_THRESHOLD})"
        return 1
    fi
    
    return 0
}

check_services() {
    local services=("hxnodes-backend" "hxnodes-frontend" "postgresql" "nginx")
    local failed_services=()
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            log_info "Service $service is running"
        else
            log_error "Service $service is not running"
            failed_services+=("$service")
        fi
    done
    
    if [ ${#failed_services[@]} -gt 0 ]; then
        local service_list=$(IFS=', '; echo "${failed_services[*]}")
        send_alert "critical" "Service Failure" "Failed services: $service_list"
        return 1
    fi
    
    return 0
}

check_database() {
    if command -v psql &> /dev/null; then
        if psql -h localhost -U hxnodes -d hxnodes -c "SELECT 1;" > /dev/null 2>&1; then
            log_info "Database connection successful"
            return 0
        else
            log_error "Database connection failed"
            send_alert "critical" "Database Error" "Cannot connect to PostgreSQL database"
            return 1
        fi
    else
        log_warning "PostgreSQL client not available, skipping database check"
        return 0
    fi
}

check_api_health() {
    local api_url="http://localhost:3001/api/health"
    local response=$(curl -s -o /dev/null -w "%{http_code}" "$api_url" 2>/dev/null || echo "000")
    
    if [ "$response" = "200" ]; then
        log_info "API health check successful"
        return 0
    else
        log_error "API health check failed (HTTP $response)"
        send_alert "critical" "API Error" "API health check failed with HTTP $response"
        return 1
    fi
}

check_node_agents() {
    local nodes_file="/tmp/hxnodes_nodes.txt"
    
    # Get list of nodes from database or config
    if [ -f "$nodes_file" ]; then
        while IFS= read -r node; do
            local node_ip=$(echo "$node" | cut -d':' -f1)
            local node_port=$(echo "$node" | cut -d':' -f2)
            
            if curl -s "http://${node_ip}:${node_port}/health" > /dev/null 2>&1; then
                log_info "Node agent $node_ip:$node_port is healthy"
            else
                log_error "Node agent $node_ip:$node_port is not responding"
                send_alert "warning" "Node Agent Down" "Node agent $node_ip:$node_port is not responding"
            fi
        done < "$nodes_file"
    else
        log_info "No node agents configured for monitoring"
    fi
}

check_backup_status() {
    local backup_dir="/var/backups/hxnodes"
    local latest_backup=$(find "$backup_dir" -name "db_*.sql" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
    
    if [ -n "$latest_backup" ]; then
        local backup_age=$(( ($(date +%s) - $(stat -c %Y "$latest_backup")) / 86400 ))
        
        if [ "$backup_age" -gt 1 ]; then
            log_warning "Latest backup is $backup_age days old"
            send_alert "warning" "Backup Warning" "Latest backup is $backup_age days old"
        else
            log_info "Backup is recent ($backup_age days old)"
        fi
    else
        log_error "No backups found"
        send_alert "critical" "Backup Error" "No database backups found"
    fi
}

check_security() {
    # Check for failed login attempts
    local failed_logins=$(grep "Failed password" /var/log/auth.log 2>/dev/null | wc -l)
    
    if [ "$failed_logins" -gt 10 ]; then
        log_warning "High number of failed login attempts: $failed_logins"
        send_alert "warning" "Security Warning" "High number of failed login attempts: $failed_logins"
    fi
    
    # Check for suspicious processes
    local suspicious_processes=$(ps aux | grep -E "(crypto|miner|mining)" | grep -v grep | wc -l)
    
    if [ "$suspicious_processes" -gt 0 ]; then
        log_error "Suspicious processes detected: $suspicious_processes"
        send_alert "critical" "Security Alert" "Suspicious processes detected on system"
    fi
}

# =============================================================================
# PERFORMANCE METRICS
# =============================================================================

collect_metrics() {
    local metrics_file="/var/log/hxnodes/metrics.json"
    local timestamp=$(date -Iseconds)
    
    # Collect system metrics
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    local mem_info=$(free | grep Mem)
    local mem_total=$(echo $mem_info | awk '{print $2}')
    local mem_used=$(echo $mem_info | awk '{print $3}')
    local mem_usage=$((mem_used * 100 / mem_total))
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | cut -d'%' -f1)
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | cut -d',' -f1)
    
    # Create metrics JSON
    cat > "$metrics_file" <<EOF
{
  "timestamp": "$timestamp",
  "system": {
    "cpu_usage": $cpu_usage,
    "memory_usage": $mem_usage,
    "disk_usage": $disk_usage,
    "load_average": $load_avg
  },
  "services": {
    "backend": $(systemctl is-active --quiet hxnodes-backend && echo "true" || echo "false"),
    "frontend": $(systemctl is-active --quiet hxnodes-frontend && echo "true" || echo "false"),
    "database": $(systemctl is-active --quiet postgresql && echo "true" || echo "false"),
    "nginx": $(systemctl is-active --quiet nginx && echo "true" || echo "false")
  }
}
EOF
    
    log_info "Metrics collected and saved to $metrics_file"
}

# =============================================================================
# CLEANUP FUNCTIONS
# =============================================================================

cleanup_old_logs() {
    local log_dir="/var/log/hxnodes"
    local days_to_keep=30
    
    find "$log_dir" -name "*.log" -type f -mtime +$days_to_keep -delete 2>/dev/null || true
    log_info "Cleaned up logs older than $days_to_keep days"
}

cleanup_temp_files() {
    local temp_dir="/tmp"
    local days_to_keep=7
    
    find "$temp_dir" -name "hxnodes_*" -type f -mtime +$days_to_keep -delete 2>/dev/null || true
    log_info "Cleaned up temporary files older than $days_to_keep days"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    log_info "Starting hxnodes system monitoring"
    
    # Create log directory if it doesn't exist
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # System health checks
    local checks_failed=0
    
    check_cpu_usage || ((checks_failed++))
    check_memory_usage || ((checks_failed++))
    check_disk_usage || ((checks_failed++))
    check_load_average || ((checks_failed++))
    check_services || ((checks_failed++))
    check_database || ((checks_failed++))
    check_api_health || ((checks_failed++))
    check_node_agents || ((checks_failed++))
    check_backup_status || ((checks_failed++))
    check_security || ((checks_failed++))
    
    # Collect performance metrics
    collect_metrics
    
    # Cleanup
    cleanup_old_logs
    cleanup_temp_files
    
    # Summary
    if [ $checks_failed -eq 0 ]; then
        log_success "All system checks passed"
        send_alert "info" "System Health" "All system checks passed successfully"
    else
        log_error "$checks_failed check(s) failed"
        send_alert "warning" "System Health" "$checks_failed system check(s) failed"
    fi
    
    log_info "Monitoring completed"
}

# Run main function
main "$@" 