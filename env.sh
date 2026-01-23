#!/bin/bash
# env.sh - Spawner Environment CLI
#
# Usage: ./env.sh <command> [args...]
#
# Commands:
#   spawn <user>                Spawn a new environment user
#   delete <user> [--hard]      Delete a user (soft by default)
#   provision <user> [options]  Install Claude Code for a user
#   reset <user> <template>     Reset user's .claude to a template
#   switch <user>               Open terminal as a user
#   backup <user>               Backup user's .claude to git
#   restore <user> [commit]     Restore from backup
#   status [user]               Show status of all or one user
#   list                        List all managed users
#   sync                        Update pai-snapshot from production
#   sync-starter                Create/update sanitized pai-starter template
#   sync-upstream               Update pai-vanilla from GitHub
#   prune                       Clean old backups (30+ days)
#   help [command]              Show help for a command
#
# Examples:
#   ./env.sh list
#   ./env.sh status Lab1
#   ./env.sh reset Lab1 vanilla
#   ./env.sh provision Lab2 --approach nvm
#   ./env.sh switch Lab1

# Don't use set -e - handle errors explicitly
# set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# =============================================================================
# HELP TEXT
# =============================================================================

show_main_help() {
    echo -e "${CYAN}${BOLD}Spawner - Environment CLI${NC}"
    echo ""
    echo "A tool for spawning and managing isolated Windows user environments."
    echo ""
    echo -e "${BOLD}Usage:${NC}"
    echo "  ./env.sh <command> [arguments]"
    echo ""
    echo -e "${BOLD}User Categories:${NC}"
    echo -e "  ${GREEN}lab${NC}   - Testing environments (Lab1, Lab2...) - reset often, any template"
    echo -e "  ${GREEN}dev${NC}   - Automation environments (Dev1...) - vanilla only, no reset"
    echo ""
    echo -e "${BOLD}Commands:${NC}"
    echo -e "  ${GREEN}spawn${NC}       Spawn a new Windows user"
    echo -e "  ${GREEN}delete${NC}      Remove a user (soft delete by default)"
    echo -e "  ${GREEN}provision${NC}   Install Claude Code CLI for a user"
    echo -e "  ${GREEN}reset${NC}       Reset user's .claude to a template"
    echo -e "  ${GREEN}switch${NC}      Open a terminal as a user"
    echo -e "  ${GREEN}backup${NC}      Backup user's .claude to git"
    echo -e "  ${GREEN}restore${NC}     Restore .claude from backup"
    echo -e "  ${GREEN}status${NC}      Show status of users"
    echo -e "  ${GREEN}list${NC}        List all managed users"
    echo -e "  ${GREEN}sync${NC}        Update pai-snapshot from production"
    echo -e "  ${GREEN}sync-starter${NC}  Create sanitized pai-starter template"
    echo -e "  ${GREEN}sync-upstream${NC} Update pai-vanilla from GitHub"
    echo -e "  ${GREEN}prune${NC}       Clean backups older than 30 days"
    echo -e "  ${GREEN}help${NC}        Show help for a command"
    echo ""
    echo -e "${BOLD}Examples:${NC}"
    echo "  ./env.sh spawn Dev1                      # Spawn dev user with Claude"
    echo "  ./env.sh spawn Lab4 --template pai-clone # Spawn lab with PAI template"
    echo "  ./env.sh spawn TestBot --cli none        # User only, no CLI"
    echo "  ./env.sh list                       # Show all users with categories"
    echo "  ./env.sh status Lab1                # Show Lab1's status"
    echo "  ./env.sh reset Lab1 vanilla         # Reset Lab1 to vanilla template"
    echo "  ./env.sh reset Dev1 pai-clone       # BLOCKED - dev users can't be reset"
    echo "  ./env.sh switch Lab1                # Open terminal as Lab1"
    echo ""
    echo -e "${BOLD}Templates:${NC}"
    echo "  vanilla     - Stock Claude Code (no PAI)"
    echo "  pai-vanilla - Daniel Miessler's original PAI (upstream)"
    echo "  pai-starter - Sanitized PAI framework (no personal data)"
    echo "  pai-clone   - Copy of admin user's production PAI"
    echo ""
    echo -e "Run ${CYAN}./env.sh help <command>${NC} for detailed help on a specific command."
}

show_command_help() {
    local cmd=$1

    case "$cmd" in
        spawn)
            echo -e "${BOLD}env spawn${NC} - Spawn a new Windows user with Claude Code"
            echo ""
            echo "Usage: ./env.sh spawn <username> [options]"
            echo ""
            echo "Spawns a new Windows user with nvm, Node.js, and Claude Code CLI."
            echo "No manual login required - everything is set up automatically!"
            echo ""
            echo "Category is auto-detected from username prefix:"
            echo "  Lab* -> lab category (Lab12345 password, any template)"
            echo "  Dev* -> dev category (Dev12345 password, vanilla only)"
            echo ""
            echo "Options:"
            echo "  --cli <opt>          CLI to install: claude (default), none"
            echo "  --template <tpl>     Template: vanilla, pai-clone, pai-starter, pai-vanilla"
            echo "  --password <pwd>     Set custom password"
            echo "  --category <cat>     Explicit category (lab, dev)"
            echo ""
            echo "Examples:"
            echo "  ./env.sh spawn Dev1                      # Dev with Claude"
            echo "  ./env.sh spawn Lab5 --template pai-clone # Lab with PAI"
            echo "  ./env.sh spawn TestBot --cli none        # User only, no CLI"
            ;;
        delete)
            echo -e "${BOLD}env delete${NC} - Remove a user"
            echo ""
            echo "Usage: ./env.sh delete <username> [options]"
            echo ""
            echo "By default, performs a soft delete (marks inactive in manifest)."
            echo "Use --hard to completely remove the Windows user and home directory."
            echo ""
            echo "Options:"
            echo "  --hard       Completely remove user and home directory"
            echo "  --no-backup  Skip backup before deletion"
            echo "  --force      Skip confirmation prompt"
            echo ""
            echo "Examples:"
            echo "  ./env.sh delete Lab3           # Soft delete (reversible)"
            echo "  ./env.sh delete Lab3 --hard    # Complete removal"
            ;;
        provision)
            echo -e "${BOLD}env provision${NC} - Install Claude Code for a user"
            echo ""
            echo "Usage: ./env.sh provision <username> [options]"
            echo ""
            echo "Installs Claude Code CLI and sets up authentication."
            echo ""
            echo "Options:"
            echo "  --approach <method>   Installation method:"
            echo "                        npm-copy - Copy from admin user (fast, offline)"
            echo "                        nvm      - Fresh install via nvm-windows"
            echo "  --template <name>     Initial template (default: vanilla)"
            echo ""
            echo "Note: Dev users are always provisioned with vanilla template."
            echo ""
            echo "Examples:"
            echo "  ./env.sh provision Lab1"
            echo "  ./env.sh provision Lab2 --approach nvm"
            echo "  ./env.sh provision Dev1  # Always vanilla"
            ;;
        reset)
            echo -e "${BOLD}env reset${NC} - Reset user's .claude to a template"
            echo ""
            echo "Usage: ./env.sh reset <username> <template> [options]"
            echo ""
            echo "Replaces the user's .claude directory with a fresh template."
            echo "Automatically backs up current state and preserves credentials."
            echo ""
            echo -e "${YELLOW}IMPORTANT: Dev users cannot be reset (they must remain vanilla).${NC}"
            echo "Use --force to override this protection (not recommended)."
            echo ""
            echo "Templates:"
            echo "  vanilla     - Stock Claude Code"
            echo "  pai-clone   - Admin user's production PAI"
            echo "  pai-vanilla - Miessler's original PAI"
            echo "  pai-starter - Sanitized PAI framework"
            echo ""
            echo "Options:"
            echo "  --no-backup   Skip automatic backup"
            echo "  --force       Skip confirmation (and override dev protection)"
            echo ""
            echo "Examples:"
            echo "  ./env.sh reset Lab1 vanilla"
            echo "  ./env.sh reset Lab2 pai-clone"
            echo "  ./env.sh reset Dev1 vanilla --force  # Override protection"
            ;;
        switch)
            echo -e "${BOLD}env switch${NC} - Open terminal as a user"
            echo ""
            echo "Usage: ./env.sh switch <username>"
            echo ""
            echo "Opens a new CMD window running as the specified user."
            echo "You will be prompted for the user's password."
            echo ""
            echo "Default passwords:"
            echo "  Lab users: Lab12345"
            echo "  Dev users: Dev12345"
            echo ""
            echo "Example:"
            echo "  ./env.sh switch Lab1"
            echo "  ./env.sh switch Dev1"
            ;;
        backup)
            echo -e "${BOLD}env backup${NC} - Backup user's .claude to git"
            echo ""
            echo "Usage: ./env.sh backup <username> [message]"
            echo ""
            echo "Creates a git commit with the user's current .claude state."
            echo "Sensitive files (.env, .credentials.json, history.jsonl) are excluded."
            echo ""
            echo "Example:"
            echo "  ./env.sh backup Lab1"
            echo "  ./env.sh backup Lab1 \"Before experimental changes\""
            ;;
        restore)
            echo -e "${BOLD}env restore${NC} - Restore .claude from backup"
            echo ""
            echo "Usage: ./env.sh restore <username> [commit]"
            echo ""
            echo "Restores the user's .claude from a previous backup."
            echo "Automatically backs up current state before restoring."
            echo ""
            echo "Options:"
            echo "  commit      Git commit hash to restore (default: latest)"
            echo "  --list      List available backups"
            echo "  --force     Skip confirmation"
            echo ""
            echo "Examples:"
            echo "  ./env.sh restore Lab1             # Restore latest"
            echo "  ./env.sh restore Lab1 abc123f     # Restore specific"
            echo "  ./env.sh restore Lab1 --list      # Show backups"
            ;;
        status)
            echo -e "${BOLD}env status${NC} - Show status of users"
            echo ""
            echo "Usage: ./env.sh status [username]"
            echo ""
            echo "Shows detailed status for all users or a specific user."
            echo "Includes category, template, and provisioning status."
            echo ""
            echo "Examples:"
            echo "  ./env.sh status         # All users"
            echo "  ./env.sh status Lab1    # Lab1 only"
            ;;
        list)
            echo -e "${BOLD}env list${NC} - List all managed users"
            echo ""
            echo "Usage: ./env.sh list"
            echo ""
            echo "Shows a compact list of all users with their category and status."
            ;;
        sync)
            echo -e "${BOLD}env sync${NC} - Update pai-snapshot template"
            echo ""
            echo "Usage: ./env.sh sync"
            echo ""
            echo "Copies admin user's current .claude to the pai-snapshot template."
            echo "Run this before resetting users to pai-clone or pai-dev."
            ;;
        sync-starter)
            echo -e "${BOLD}env sync-starter${NC} - Create sanitized pai-starter template"
            echo ""
            echo "Usage: ./env.sh sync-starter [backup-count]"
            echo ""
            echo "Copies admin user's .claude, removes personal data, and creates"
            echo "a generic starter template that can be shared publicly."
            echo ""
            echo "Sanitization includes:"
            echo "  - Removing credentials, history, logs"
            echo "  - Clearing IDENTITY.md, CONTACTS.md"
            echo "  - Replacing personal identifiers (per sanitize-rules.txt)"
            echo "  - Validating no personal data remains"
            echo ""
            echo "Options:"
            echo "  backup-count   Number of old versions to keep (default: 3)"
            echo ""
            echo "Example:"
            echo "  ./env.sh sync-starter"
            ;;
        sync-upstream)
            echo -e "${BOLD}env sync-upstream${NC} - Update pai-vanilla from GitHub"
            echo ""
            echo "Usage: ./env.sh sync-upstream"
            echo ""
            echo "Downloads the latest version of Daniel Miessler's PAI from GitHub"
            echo "and updates the pai-vanilla template."
            echo ""
            echo "Source: https://github.com/danielmiessler/pai"
            ;;
        prune)
            echo -e "${BOLD}env prune${NC} - Clean old backups"
            echo ""
            echo "Usage: ./env.sh prune [--days <n>]"
            echo ""
            echo "Removes backup commits older than 30 days (configurable)."
            echo ""
            echo "Options:"
            echo "  --days <n>   Days to keep (default: 30)"
            echo "  --dry-run    Show what would be deleted"
            ;;
        *)
            echo "Unknown command: $cmd"
            echo ""
            show_main_help
            exit 1
            ;;
    esac
}

# =============================================================================
# COMMAND ROUTER
# =============================================================================

COMMAND=${1:-help}
shift 2>/dev/null || true

case "$COMMAND" in
    # Main commands - delegate to lib/*.sh
    spawn)
        source "$LIB_DIR/common.sh"
        source "$LIB_DIR/spawn.sh"
        cmd_spawn "$@"
        ;;
    delete)
        source "$LIB_DIR/common.sh"
        source "$LIB_DIR/delete.sh"
        cmd_delete "$@"
        ;;
    provision)
        source "$LIB_DIR/common.sh"
        source "$LIB_DIR/provision.sh"
        cmd_provision "$@"
        ;;
    reset)
        source "$LIB_DIR/common.sh"
        source "$LIB_DIR/reset.sh"
        cmd_reset "$@"
        ;;
    switch)
        source "$LIB_DIR/common.sh"
        source "$LIB_DIR/switch.sh"
        cmd_switch "$@"
        ;;
    backup)
        source "$LIB_DIR/common.sh"
        source "$LIB_DIR/backup.sh"
        cmd_backup "$@"
        ;;
    restore)
        source "$LIB_DIR/common.sh"
        source "$LIB_DIR/restore.sh"
        cmd_restore "$@"
        ;;
    status)
        source "$LIB_DIR/common.sh"
        source "$LIB_DIR/status.sh"
        cmd_status "$@"
        ;;
    list)
        source "$LIB_DIR/common.sh"
        source "$LIB_DIR/status.sh"
        cmd_list "$@"
        ;;
    sync)
        source "$LIB_DIR/common.sh"
        source "$LIB_DIR/sync.sh"
        cmd_sync "$@"
        ;;
    sync-starter)
        source "$LIB_DIR/common.sh"
        source "$LIB_DIR/sync.sh"
        cmd_sync_starter "$@"
        ;;
    sync-upstream)
        source "$LIB_DIR/common.sh"
        source "$LIB_DIR/sync.sh"
        cmd_sync_upstream "$@"
        ;;
    prune)
        source "$LIB_DIR/common.sh"
        source "$LIB_DIR/prune.sh"
        cmd_prune "$@"
        ;;

    # Help
    help)
        if [ -n "$1" ]; then
            show_command_help "$1"
        else
            show_main_help
        fi
        ;;
    -h|--help)
        show_main_help
        ;;

    # Unknown command
    *)
        echo -e "${RED}Unknown command: $COMMAND${NC}"
        echo ""
        show_main_help
        exit 1
        ;;
esac
