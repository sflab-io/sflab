#!/usr/bin/env bash

#############################################
# Restic Backup Script for MacBook → TrueNAS
#############################################

set -euo pipefail

# ============================================
# CONFIGURATION
# ============================================

# Directories to backup (add or modify as needed)
BACKUP_DIRS=(
    "$HOME/Documents"
    "$HOME/projects"
    "$HOME/Desktop"
    # Add more directories here
)

# TrueNAS SFTP Repository Configuration
# Using SSH config host alias 'truenas-backup' which defines:
# - HostName: 192.168.30.108
# - Port: 22022
# - User: rbackup
# - IdentityFile: ~/.ssh/id_rsa
TRUENAS_HOST="truenas-backup"
BACKUP_PATH="/mnt/storage/storage-share-smb/rbackup"  # Adjust to your TrueNAS dataset path

# Restic Repository URL (SFTP)
REPO="sftp:${TRUENAS_HOST}:${BACKUP_PATH}"

# Restic password file (will be created if doesn't exist)
RESTIC_PASSWORD_FILE="$HOME/.config/restic/password"

# Retention Policy for pruning
KEEP_DAILY=7
KEEP_WEEKLY=4
KEEP_MONTHLY=6
KEEP_YEARLY=2

# Exclusion patterns
EXCLUDE_PATTERNS=(
    "*.tmp"
    "*.cache"
    ".DS_Store"
    "node_modules"
    ".venv"
    ".git"
    ".ansible"
    ".pytest_cache"
    "__pycache__"
    ".terragrunt-stack"
    "tmp"
    "dist"
    "build"
    "Cache"
    "Caches"
    ".Trash"
)

# ============================================
# HELPER FUNCTIONS
# ============================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if restic is installed
check_restic() {
    if ! command -v restic &> /dev/null; then
        log_error "restic is not installed!"
        log_info "Install with: brew install restic"
        exit 1
    fi
}

# Test SSH connection to TrueNAS
test_connection() {
    log_info "Testing SSH connection to TrueNAS..."
    if ssh -o ConnectTimeout=5 -o BatchMode=yes "${TRUENAS_HOST}" "echo 'Connection successful'" &> /dev/null; then
        log_success "SSH connection successful"
        return 0
    else
        log_error "Cannot connect to TrueNAS server"
        log_info "Test manually: ssh ${TRUENAS_HOST}"
        return 1
    fi
}

# Setup restic password file
setup_password() {
    if [ ! -f "$RESTIC_PASSWORD_FILE" ]; then
        log_warning "Restic password file not found"
        mkdir -p "$(dirname "$RESTIC_PASSWORD_FILE")"
        echo -n "Enter a password for restic repository encryption: "
        read -s password
        echo
        echo -n "Confirm password: "
        read -s password_confirm
        echo

        if [ "$password" != "$password_confirm" ]; then
            log_error "Passwords do not match!"
            exit 1
        fi

        echo "$password" > "$RESTIC_PASSWORD_FILE"
        chmod 600 "$RESTIC_PASSWORD_FILE"
        log_success "Password file created at $RESTIC_PASSWORD_FILE"
    fi
}

# Export restic environment variables
setup_restic_env() {
    export RESTIC_REPOSITORY="$REPO"
    export RESTIC_PASSWORD_FILE="$RESTIC_PASSWORD_FILE"

    # SSH config handles connection details (port, user, identity file)
    # for the 'truenas-backup' host alias
}

# ============================================
# MAIN FUNCTIONS
# ============================================

# Initialize restic repository
init_repo() {
    log_info "Initializing restic repository..."

    if ! test_connection; then
        exit 1
    fi

    setup_password
    setup_restic_env

    # Check if repository already exists
    if restic snapshots &> /dev/null; then
        log_warning "Repository already initialized"
        restic snapshots --compact
        return 0
    fi

    # Initialize new repository
    log_info "Creating new repository at $REPO"
    if restic init; then
        log_success "Repository initialized successfully"
    else
        log_error "Failed to initialize repository"
        exit 1
    fi
}

# Perform backup
perform_backup() {
    log_info "Starting backup process..."

    if ! test_connection; then
        exit 1
    fi

    setup_restic_env

    # Build exclusion arguments
    EXCLUDE_ARGS=()
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        EXCLUDE_ARGS+=(--exclude "$pattern")
    done

    # Check if directories exist
    VALID_DIRS=()
    for dir in "${BACKUP_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            VALID_DIRS+=("$dir")
        else
            log_warning "Directory not found, skipping: $dir"
        fi
    done

    if [ ${#VALID_DIRS[@]} -eq 0 ]; then
        log_error "No valid directories to backup!"
        exit 1
    fi

    log_info "Backing up ${#VALID_DIRS[@]} directories..."

    # Perform backup with tags
    HOSTNAME=$(hostname -s)
    if restic backup "${VALID_DIRS[@]}" \
        "${EXCLUDE_ARGS[@]}" \
        --tag "macbook" \
        --tag "$HOSTNAME" \
        --tag "$(date +%Y-%m-%d)" \
        --verbose; then
        log_success "Backup completed successfully"

        # Show latest snapshot
        log_info "Latest snapshot:"
        restic snapshots --compact --latest 1
    else
        log_error "Backup failed!"
        exit 1
    fi
}

# Prune old backups according to retention policy
prune_backups() {
    log_info "Pruning old backups..."

    if ! test_connection; then
        exit 1
    fi

    setup_restic_env

    log_info "Retention policy:"
    log_info "  - Keep last $KEEP_DAILY daily backups"
    log_info "  - Keep last $KEEP_WEEKLY weekly backups"
    log_info "  - Keep last $KEEP_MONTHLY monthly backups"
    log_info "  - Keep last $KEEP_YEARLY yearly backups"

    if restic forget \
        --keep-daily "$KEEP_DAILY" \
        --keep-weekly "$KEEP_WEEKLY" \
        --keep-monthly "$KEEP_MONTHLY" \
        --keep-yearly "$KEEP_YEARLY" \
        --prune \
        --verbose; then
        log_success "Pruning completed successfully"
    else
        log_error "Pruning failed!"
        exit 1
    fi

    # Check repository integrity
    log_info "Checking repository integrity..."
    if restic check; then
        log_success "Repository check passed"
    else
        log_warning "Repository check found issues"
    fi
}

# List all snapshots
list_snapshots() {
    log_info "Listing snapshots..."

    setup_restic_env

    if restic snapshots; then
        echo
        log_info "Repository statistics:"
        restic stats
    else
        log_error "Failed to list snapshots"
        exit 1
    fi
}

# Restore from backup
restore_backup() {
    log_info "Restore functionality"

    setup_restic_env

    echo
    log_info "Available snapshots:"
    restic snapshots --compact

    echo
    echo -n "Enter snapshot ID to restore (or 'latest'): "
    read -r snapshot_id

    echo -n "Enter restore destination path: "
    read -r restore_path

    if [ -z "$snapshot_id" ] || [ -z "$restore_path" ]; then
        log_error "Snapshot ID and restore path are required"
        exit 1
    fi

    mkdir -p "$restore_path"

    log_info "Restoring snapshot $snapshot_id to $restore_path..."
    if restic restore "$snapshot_id" --target "$restore_path" --verbose; then
        log_success "Restore completed successfully"
    else
        log_error "Restore failed!"
        exit 1
    fi
}

# ============================================
# INTERACTIVE MENU
# ============================================

show_menu() {
    echo
    echo "=========================================="
    echo "  MacBook → TrueNAS Restic Backup"
    echo "=========================================="
    echo "Repository: $REPO"
    echo "=========================================="
    echo
    echo "1) Initialize repository"
    echo "2) Perform backup"
    echo "3) Prune old backups"
    echo "4) List snapshots"
    echo "5) Restore from backup"
    echo "6) Exit"
    echo
}

interactive_menu() {
    check_restic

    while true; do
        show_menu
        echo -n "Select an option [1-6]: "
        read -r choice

        case $choice in
            1)
                init_repo
                ;;
            2)
                perform_backup
                ;;
            3)
                prune_backups
                ;;
            4)
                list_snapshots
                ;;
            5)
                restore_backup
                ;;
            6)
                log_info "Exiting..."
                exit 0
                ;;
            *)
                log_error "Invalid option. Please select 1-6."
                ;;
        esac

        echo
        echo -n "Press Enter to continue..."
        read -r
    done
}

# ============================================
# MAIN SCRIPT
# ============================================

main() {
    # If no arguments provided, show interactive menu
    if [ $# -eq 0 ]; then
        interactive_menu
        exit 0
    fi

    # Handle command-line arguments
    check_restic

    case "$1" in
        init)
            init_repo
            ;;
        backup)
            perform_backup
            ;;
        prune)
            prune_backups
            ;;
        list)
            list_snapshots
            ;;
        restore)
            restore_backup
            ;;
        *)
            echo "Usage: $0 {init|backup|prune|list|restore}"
            echo "  Or run without arguments for interactive menu"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
