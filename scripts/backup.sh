#!/bin/bash

# =============================================================================
# hxnodes Backup Script
# =============================================================================
# This script creates encrypted backups of database, files, and configurations
# Run this script via cron for automated backups
# =============================================================================

set -e

# Configuration
BACKUP_DIR="/var/backups/hxnodes"
ENCRYPTION_KEY="your-encryption-key-here"
RETENTION_DAYS=30
COMPRESSION_LEVEL=9

# Database configuration
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="hxnodes"
DB_USER="hxnodes"

# File paths
UPLOAD_PATH="/var/hxnodes/uploads"
CONFIG_PATH="/etc/hxnodes"
LOG_PATH="/var/log/hxnodes"

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
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_PATH/backup.log"
}

log_info() {
    log "INFO: $1"
    echo -e "${BLUE}INFO: $1${NC}"
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
# UTILITY FUNCTIONS
# =============================================================================

check_dependencies() {
    local deps=("pg_dump" "gzip" "openssl" "tar")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "Required dependency not found: $dep"
            exit 1
        fi
    done
    
    log_info "All dependencies are available"
}

create_backup_directories() {
    local dirs=(
        "$BACKUP_DIR"
        "$BACKUP_DIR/database"
        "$BACKUP_DIR/files"
        "$BACKUP_DIR/config"
        "$BACKUP_DIR/logs"
        "$BACKUP_DIR/temp"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
        log_info "Created directory: $dir"
    done
}

generate_backup_name() {
    local type="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    echo "${type}_${timestamp}"
}

encrypt_file() {
    local input_file="$1"
    local output_file="$2"
    
    if [ -n "$ENCRYPTION_KEY" ]; then
        openssl enc -aes-256-cbc -salt -in "$input_file" -out "$output_file" -k "$ENCRYPTION_KEY"
        rm "$input_file"
        log_info "Encrypted: $output_file"
    else
        mv "$input_file" "$output_file"
        log_info "No encryption key provided, file saved as: $output_file"
    fi
}

# =============================================================================
# BACKUP FUNCTIONS
# =============================================================================

backup_database() {
    local backup_name=$(generate_backup_name "db")
    local temp_file="$BACKUP_DIR/temp/${backup_name}.sql"
    local compressed_file="$BACKUP_DIR/temp/${backup_name}.sql.gz"
    local final_file="$BACKUP_DIR/database/${backup_name}.sql.gz"
    
    log_info "Starting database backup..."
    
    # Create database dump
    if PGPASSWORD="$DB_PASSWORD" pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        --verbose --clean --no-owner --no-privileges > "$temp_file" 2>/dev/null; then
        
        # Compress the dump
        gzip -$COMPRESSION_LEVEL "$temp_file"
        
        # Encrypt if key is provided
        if [ -n "$ENCRYPTION_KEY" ]; then
            local encrypted_file="$BACKUP_DIR/database/${backup_name}.sql.gz.enc"
            encrypt_file "$compressed_file" "$encrypted_file"
            final_file="$encrypted_file"
        else
            mv "$compressed_file" "$final_file"
        fi
        
        log_success "Database backup completed: $final_file"
        echo "$final_file"
    else
        log_error "Database backup failed"
        rm -f "$temp_file" "$compressed_file"
        return 1
    fi
}

backup_files() {
    local backup_name=$(generate_backup_name "files")
    local temp_file="$BACKUP_DIR/temp/${backup_name}.tar"
    local compressed_file="$BACKUP_DIR/temp/${backup_name}.tar.gz"
    local final_file="$BACKUP_DIR/files/${backup_name}.tar.gz"
    
    log_info "Starting file backup..."
    
    # Check if upload directory exists
    if [ ! -d "$UPLOAD_PATH" ]; then
        log_warning "Upload directory not found: $UPLOAD_PATH"
        return 0
    fi
    
    # Create tar archive
    if tar -cf "$temp_file" -C "$(dirname "$UPLOAD_PATH")" "$(basename "$UPLOAD_PATH")" 2>/dev/null; then
        
        # Compress the archive
        gzip -$COMPRESSION_LEVEL "$temp_file"
        
        # Encrypt if key is provided
        if [ -n "$ENCRYPTION_KEY" ]; then
            local encrypted_file="$BACKUP_DIR/files/${backup_name}.tar.gz.enc"
            encrypt_file "$compressed_file" "$encrypted_file"
            final_file="$encrypted_file"
        else
            mv "$compressed_file" "$final_file"
        fi
        
        log_success "File backup completed: $final_file"
        echo "$final_file"
    else
        log_error "File backup failed"
        rm -f "$temp_file" "$compressed_file"
        return 1
    fi
}

backup_config() {
    local backup_name=$(generate_backup_name "config")
    local temp_file="$BACKUP_DIR/temp/${backup_name}.tar"
    local compressed_file="$BACKUP_DIR/temp/${backup_name}.tar.gz"
    local final_file="$BACKUP_DIR/config/${backup_name}.tar.gz"
    
    log_info "Starting configuration backup..."
    
    # Check if config directory exists
    if [ ! -d "$CONFIG_PATH" ]; then
        log_warning "Config directory not found: $CONFIG_PATH"
        return 0
    fi
    
    # Create tar archive
    if tar -cf "$temp_file" -C "$(dirname "$CONFIG_PATH")" "$(basename "$CONFIG_PATH")" 2>/dev/null; then
        
        # Compress the archive
        gzip -$COMPRESSION_LEVEL "$temp_file"
        
        # Encrypt if key is provided
        if [ -n "$ENCRYPTION_KEY" ]; then
            local encrypted_file="$BACKUP_DIR/config/${backup_name}.tar.gz.enc"
            encrypt_file "$compressed_file" "$encrypted_file"
            final_file="$encrypted_file"
        else
            mv "$compressed_file" "$final_file"
        fi
        
        log_success "Configuration backup completed: $final_file"
        echo "$final_file"
    else
        log_error "Configuration backup failed"
        rm -f "$temp_file" "$compressed_file"
        return 1
    fi
}

backup_logs() {
    local backup_name=$(generate_backup_name "logs")
    local temp_file="$BACKUP_DIR/temp/${backup_name}.tar"
    local compressed_file="$BACKUP_DIR/temp/${backup_name}.tar.gz"
    local final_file="$BACKUP_DIR/logs/${backup_name}.tar.gz"
    
    log_info "Starting log backup..."
    
    # Check if log directory exists
    if [ ! -d "$LOG_PATH" ]; then
        log_warning "Log directory not found: $LOG_PATH"
        return 0
    fi
    
    # Create tar archive
    if tar -cf "$temp_file" -C "$(dirname "$LOG_PATH")" "$(basename "$LOG_PATH")" 2>/dev/null; then
        
        # Compress the archive
        gzip -$COMPRESSION_LEVEL "$temp_file"
        
        # Encrypt if key is provided
        if [ -n "$ENCRYPTION_KEY" ]; then
            local encrypted_file="$BACKUP_DIR/logs/${backup_name}.tar.gz.enc"
            encrypt_file "$compressed_file" "$encrypted_file"
            final_file="$encrypted_file"
        else
            mv "$compressed_file" "$final_file"
        fi
        
        log_success "Log backup completed: $final_file"
        echo "$final_file"
    else
        log_error "Log backup failed"
        rm -f "$temp_file" "$compressed_file"
        return 1
    fi
}

# =============================================================================
# VERIFICATION FUNCTIONS
# =============================================================================

verify_backup() {
    local backup_file="$1"
    local backup_type="$2"
    
    log_info "Verifying backup: $backup_file"
    
    # Check if file exists and has size
    if [ ! -f "$backup_file" ] || [ ! -s "$backup_file" ]; then
        log_error "Backup file is missing or empty: $backup_file"
        return 1
    fi
    
    # Get file size
    local file_size=$(stat -c%s "$backup_file")
    log_info "Backup file size: $(numfmt --to=iec $file_size)"
    
    # Test decompression for non-encrypted files
    if [[ "$backup_file" != *.enc ]]; then
        if gzip -t "$backup_file" 2>/dev/null; then
            log_success "Backup verification passed: $backup_file"
            return 0
        else
            log_error "Backup verification failed: $backup_file"
            return 1
        fi
    else
        log_info "Encrypted backup, skipping compression test"
        return 0
    fi
}

# =============================================================================
# CLEANUP FUNCTIONS
# =============================================================================

cleanup_old_backups() {
    log_info "Cleaning up old backups (older than $RETENTION_DAYS days)..."
    
    local backup_types=("database" "files" "config" "logs")
    local deleted_count=0
    
    for type in "${backup_types[@]}"; do
        local type_dir="$BACKUP_DIR/$type"
        if [ -d "$type_dir" ]; then
            local deleted=$(find "$type_dir" -name "*.gz*" -type f -mtime +$RETENTION_DAYS -delete -print | wc -l)
            deleted_count=$((deleted_count + deleted))
            if [ "$deleted" -gt 0 ]; then
                log_info "Deleted $deleted old $type backup(s)"
            fi
        fi
    done
    
    log_success "Cleanup completed: $deleted_count old backup(s) removed"
}

cleanup_temp_files() {
    log_info "Cleaning up temporary files..."
    rm -rf "$BACKUP_DIR/temp"/*
    log_success "Temporary files cleaned up"
}

# =============================================================================
# RESTORE FUNCTIONS
# =============================================================================

decrypt_file() {
    local input_file="$1"
    local output_file="$2"
    
    if [ -n "$ENCRYPTION_KEY" ] && [[ "$input_file" == *.enc ]]; then
        openssl enc -aes-256-cbc -d -in "$input_file" -out "$output_file" -k "$ENCRYPTION_KEY"
        log_info "Decrypted: $output_file"
    else
        cp "$input_file" "$output_file"
        log_info "Copied: $output_file"
    fi
}

restore_database() {
    local backup_file="$1"
    local temp_file="$BACKUP_DIR/temp/restore_db.sql.gz"
    
    log_info "Starting database restore from: $backup_file"
    
    # Decrypt if necessary
    if [[ "$backup_file" == *.enc ]]; then
        decrypt_file "$backup_file" "$temp_file"
    else
        cp "$backup_file" "$temp_file"
    fi
    
    # Decompress and restore
    gunzip "$temp_file"
    local sql_file="${temp_file%.gz}"
    
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" < "$sql_file"; then
        log_success "Database restore completed"
        rm -f "$sql_file"
    else
        log_error "Database restore failed"
        rm -f "$sql_file"
        return 1
    fi
}

restore_files() {
    local backup_file="$1"
    local temp_file="$BACKUP_DIR/temp/restore_files.tar.gz"
    local extract_dir="$BACKUP_DIR/temp/extract"
    
    log_info "Starting file restore from: $backup_file"
    
    # Create extract directory
    mkdir -p "$extract_dir"
    
    # Decrypt if necessary
    if [[ "$backup_file" == *.enc ]]; then
        decrypt_file "$backup_file" "$temp_file"
    else
        cp "$backup_file" "$temp_file"
    fi
    
    # Extract files
    tar -xzf "$temp_file" -C "$extract_dir"
    
    # Restore to original location
    if [ -d "$extract_dir/var/hxnodes/uploads" ]; then
        rsync -av "$extract_dir/var/hxnodes/uploads/" "$UPLOAD_PATH/"
        log_success "File restore completed"
    else
        log_error "File restore failed - invalid backup structure"
        return 1
    fi
    
    # Cleanup
    rm -rf "$extract_dir" "$temp_file"
}

# =============================================================================
# REPORTING FUNCTIONS
# =============================================================================

generate_backup_report() {
    local report_file="$BACKUP_DIR/backup_report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" <<EOF
hxnodes Backup Report
====================
Date: $(date)
Duration: $SECONDS seconds

Backup Summary:
EOF
    
    # Count backups by type
    local backup_types=("database" "files" "config" "logs")
    for type in "${backup_types[@]}"; do
        local type_dir="$BACKUP_DIR/$type"
        if [ -d "$type_dir" ]; then
            local count=$(find "$type_dir" -name "*.gz*" -type f | wc -l)
            local total_size=$(find "$type_dir" -name "*.gz*" -type f -exec stat -c%s {} + | awk '{sum+=$1} END {print sum+0}')
            echo "  $type: $count backup(s), $(numfmt --to=iec $total_size)" >> "$report_file"
        fi
    done
    
    echo "" >> "$report_file"
    echo "Disk Usage:" >> "$report_file"
    df -h "$BACKUP_DIR" >> "$report_file"
    
    log_info "Backup report generated: $report_file"
    echo "$report_file"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    local start_time=$(date +%s)
    local backup_files=()
    local failed_backups=0
    
    log_info "Starting hxnodes backup process"
    
    # Check dependencies
    check_dependencies
    
    # Create backup directories
    create_backup_directories
    
    # Perform backups
    log_info "Starting backup operations..."
    
    # Database backup
    if db_backup=$(backup_database 2>/dev/null); then
        backup_files+=("$db_backup")
        verify_backup "$db_backup" "database" || ((failed_backups++))
    else
        ((failed_backups++))
    fi
    
    # File backup
    if file_backup=$(backup_files 2>/dev/null); then
        backup_files+=("$file_backup")
        verify_backup "$file_backup" "files" || ((failed_backups++))
    else
        ((failed_backups++))
    fi
    
    # Configuration backup
    if config_backup=$(backup_config 2>/dev/null); then
        backup_files+=("$config_backup")
        verify_backup "$config_backup" "config" || ((failed_backups++))
    else
        ((failed_backups++))
    fi
    
    # Log backup
    if log_backup=$(backup_logs 2>/dev/null); then
        backup_files+=("$log_backup")
        verify_backup "$log_backup" "logs" || ((failed_backups++))
    else
        ((failed_backups++))
    fi
    
    # Cleanup
    cleanup_old_backups
    cleanup_temp_files
    
    # Generate report
    local report_file=$(generate_backup_report)
    
    # Calculate duration
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Final summary
    if [ $failed_backups -eq 0 ]; then
        log_success "Backup process completed successfully in ${duration}s"
        log_info "Created ${#backup_files[@]} backup(s)"
        log_info "Report: $report_file"
    else
        log_error "Backup process completed with $failed_backups failure(s) in ${duration}s"
        log_info "Created ${#backup_files[@]} backup(s)"
        log_info "Report: $report_file"
        exit 1
    fi
}

# =============================================================================
# COMMAND LINE INTERFACE
# =============================================================================

case "${1:-backup}" in
    "backup")
        main
        ;;
    "restore")
        if [ -z "$2" ]; then
            echo "Usage: $0 restore <backup_file> [type]"
            echo "Types: database, files, config, logs"
            exit 1
        fi
        
        case "${3:-database}" in
            "database")
                restore_database "$2"
                ;;
            "files")
                restore_files "$2"
                ;;
            *)
                echo "Unknown restore type: $3"
                exit 1
                ;;
        esac
        ;;
    "list")
        echo "Available backups:"
        find "$BACKUP_DIR" -name "*.gz*" -type f | sort
        ;;
    "cleanup")
        cleanup_old_backups
        ;;
    *)
        echo "Usage: $0 {backup|restore|list|cleanup}"
        exit 1
        ;;
esac 