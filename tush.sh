#!/usr/bin/env bash

set -e

# Error handling function
handle_error() {
    local error_msg="$1"
    local error_code="${2:-1}"
    echo "❌ Error: $error_msg" >&2
    log_action "ERROR: $error_msg"
    exit "$error_code"
}

# Backup function
backup_file() {
    local file="$1"
    if [ -e "$file" ]; then
        local backup="${file}.bak.$(date +%Y%m%d_%H%M%S)"
        cp -r "$file" "$backup"
        log_action "Created backup: $backup"
    fi
}

# Check for required commands
check_dependencies() {
    local deps=("git" "find" "stow" "realpath" "diff")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "❌ Missing dependencies: ${missing_deps[*]}"
        echo "Would you like to install them? (y/N)"
        read -r install_choice
        if [[ "$install_choice" =~ ^[Yy]$ ]]; then
            install_dependencies "${missing_deps[@]}"
        else
            handle_error "Required dependencies not installed"
        fi
    fi
}

# Install dependencies based on package manager
install_dependencies() {
    local deps=("$@")
    if command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm "${deps[@]}"
    elif command -v apt &>/dev/null; then
        sudo apt install -y "${deps[@]}"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y "${deps[@]}"
    elif command -v zypper &>/dev/null; then
        sudo zypper install -y "${deps[@]}"
    else
        handle_error "Unsupported package manager"
    fi
}

# Configuration
CONFIG_DIR="$HOME/.config/tersus"
CONFIG_FILE="$CONFIG_DIR/tersus-home.conf"
LOG_FILE="$CONFIG_DIR/tush.log"
README_FILE="$CONFIG_DIR/README.md"
SYMLINKS_FILE="$CONFIG_DIR/symlinks.txt"
BACKUP_DIR="$CONFIG_DIR/backups"
DOTFILES=()  # Initialize empty array

# Create necessary directories
mkdir -p "$CONFIG_DIR" "$BACKUP_DIR" || handle_error "Failed to create config directories"

function track_symlink() {
    local source="$1"
    local target="$2"
    echo "$source|$target|$(date +%Y-%m-%d_%H:%M:%S)" >> "$SYMLINKS_FILE"
}

function remove_tracked_symlinks() {
    if [ -f "$SYMLINKS_FILE" ]; then
        while IFS='|' read -r source target _; do
            if [ -L "$target" ]; then
                rm -f "$target"
                log_action "Removed symlink: $target"
            fi
        done < "$SYMLINKS_FILE"
        backup_file "$SYMLINKS_FILE"
        rm -f "$SYMLINKS_FILE"
    fi
}

function setup_clean_home() {
    read -rp "📦 Name your modular home directory (e.g., tersus): " CLEAN_HOME_NAME
    CLEAN_HOME="$HOME/$CLEAN_HOME_NAME"
    
    # Backup existing clean home if it exists
    if [ -d "$CLEAN_HOME" ]; then
        backup_file "$CLEAN_HOME"
    fi
    
    mkdir -p "$CLEAN_HOME"
    echo "CLEAN_HOME=$CLEAN_HOME" >> "$CONFIG_FILE"
    log_action "Created clean home: $CLEAN_HOME"

    # Create standard directories in clean home
    for folder in Desktop Documents Downloads Music Pictures Public Templates Videos; do
        TARGET="$HOME/$folder"
        LINK="$CLEAN_HOME/$folder"
        if [ -d "$TARGET" ] && [ ! -L "$LINK" ]; then
            if [ "$DRY_RUN" = false ]; then
                ln -sfn "$TARGET" "$LINK"
                track_symlink "$TARGET" "$LINK"
            fi
            log_action "Linked $TARGET → $LINK"
        fi
    done
}

function scan_config_for_dotfiles() {
    echo "🔍 Scanning ~/.config for potential dotfiles..."
    local config_dirs=()
    while IFS= read -r dir; do
        if [ -d "$dir" ] && [ ! -L "$dir" ]; then
            config_dirs+=("$(basename "$dir")")
        fi
    done < <(find "$HOME/.config" -mindepth 1 -maxdepth 1 -type d)

    if [ ${#config_dirs[@]} -eq 0 ]; then
        echo "No config directories found to migrate."
        return
    fi

    echo "Found the following config directories:"
    select dir in "${config_dirs[@]}" "Done"; do
        if [[ "$dir" == "Done" ]]; then
            break
        elif [[ -n "$dir" ]]; then
            DOTFILES+=("$dir")
            echo "Added $dir to dotfiles list"
        fi
    done
}

function setup_dotfiles_repo() {
    read -rp "📁 Where do you want to store your dotfiles? [default: ~/.dotfiles]: " DOTFILES_DIR
    DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
    
    # Backup existing dotfiles directory if it exists
    if [ -d "$DOTFILES_DIR" ]; then
        backup_file "$DOTFILES_DIR"
    fi
    
    echo "DOTFILES_DIR=$DOTFILES_DIR" >> "$CONFIG_FILE"
    mkdir -p "$DOTFILES_DIR"

    # Ask about remote repository
    read -rp "Would you like to set up a remote repository for your dotfiles? (y/N): " setup_remote
    if [[ "$setup_remote" =~ ^[Yy]$ ]]; then
        read -rp "Enter remote repository URL: " remote_url
        if [ -n "$remote_url" ]; then
            cd "$DOTFILES_DIR"
            git init
            git remote add origin "$remote_url"
            echo "REMOTE_REPO=$remote_url" >> "$CONFIG_FILE"
            
            # Create .gitignore
            cat > "$DOTFILES_DIR/.gitignore" << EOF
# Backup files
*.bak
*.backup
*~

# System files
.DS_Store
Thumbs.db

# Temporary files
*.tmp
*.temp
EOF
        fi
    fi
}

function stow_dotfiles() {
    for name in "${DOTFILES[@]}"; do
        local config_path="$HOME/.config/$name"
        local stow_path="$DOTFILES_DIR/$name"
        
        if [ -d "$config_path" ]; then
            # Create stow directory structure
            mkdir -p "$stow_path/.config"
            
            # Create symlink in stow directory
            if [ "$DRY_RUN" = false ]; then
                ln -sfn "$config_path" "$stow_path/.config/$name"
                track_symlink "$config_path" "$stow_path/.config/$name"
            fi
            
            # Stow the dotfile
            if [ "$DRY_RUN" = false ]; then
                (cd "$DOTFILES_DIR" && stow "$name")
            fi
            log_action "✅ Stowed $name"
        fi
    done
}

function rollback_all() {
    echo "⚠️  Rolling back all changes..."
    
    # Unstow all dotfiles
    for name in "${DOTFILES[@]}"; do
        if [ -d "$DOTFILES_DIR/$name" ]; then
            if [ "$DRY_RUN" = false ]; then
                (cd "$DOTFILES_DIR" && stow -D "$name")
            fi
            log_action "Unstowed $name"
        fi
    done
    
    # Remove tracked symlinks
    remove_tracked_symlinks
    
    # Remove clean home directory
    if [ -d "$CLEAN_HOME" ]; then
        if [ "$DRY_RUN" = false ]; then
            rm -rf "$CLEAN_HOME"
        fi
        log_action "Removed clean home directory"
    fi
}

function check_current_setup() {
    echo "📊 Current Setup Status:"
    echo "------------------------"
    
    # Check clean home
    if [ -d "$CLEAN_HOME" ]; then
        echo "✅ Clean home directory: $CLEAN_HOME"
        echo "  Contents:"
        ls -la "$CLEAN_HOME"
    else
        echo "❌ Clean home directory not found"
    fi
    
    # Check dotfiles
    echo "📁 Dotfiles:"
    for name in "${DOTFILES[@]}"; do
        if [ -d "$DOTFILES_DIR/$name" ]; then
            echo "  ✅ $name"
            echo "    Last modified: $(stat -c %y "$DOTFILES_DIR/$name")"
        else
            echo "  ❌ $name"
        fi
    done
    
    # Check symlinks
    echo "🔗 Symlinks:"
    if [ -f "$SYMLINKS_FILE" ]; then
        while IFS='|' read -r source target timestamp; do
            if [ -L "$target" ]; then
                echo "  ✅ $target (created: $timestamp)"
            else
                echo "  ❌ $target (broken, created: $timestamp)"
            fi
        done < "$SYMLINKS_FILE"
    fi
    
    # Check git status
    if [ -d "$DOTFILES_DIR/.git" ]; then
        echo "📦 Git Status:"
        cd "$DOTFILES_DIR"
        git status --short
    fi
}

function update_remote_repo() {
    if [ -d "$DOTFILES_DIR/.git" ]; then
        cd "$DOTFILES_DIR"
        
        # Check for changes
        if git diff --quiet; then
            echo "No changes to commit"
            return
        fi
        
        # Show changes
        echo "Changes to be committed:"
        git diff --stat
        
        # Ask for commit message
        read -rp "Enter commit message [Update dotfiles]: " commit_msg
        commit_msg="${commit_msg:-Update dotfiles}"
        
        # Commit and push
        git add .
        git commit -m "$commit_msg"
        git push origin main
        echo "✅ Updated remote repository"
    else
        echo "❌ No git repository found"
    fi
}

function restore_backup() {
    echo "Available backups:"
    select backup in "$BACKUP_DIR"/* "Cancel"; do
        if [[ "$backup" == "Cancel" ]]; then
            return
        elif [[ -n "$backup" ]]; then
            echo "Restoring from $backup..."
            cp -r "$backup" "$CONFIG_DIR"
            echo "✅ Backup restored"
            return
        fi
    done
}

function main_menu() {
    print_banner
    if [ -f "$CONFIG_FILE" ]; then
        echo "Welcome back to Tush 🌒"
        echo "[1] Add new dotfiles"
        echo "[2] Rollback all changes"
        echo "[3] Check current setup"
        echo "[4] Manage aliases"
        echo "[5] Update remote repository"
        echo "[6] Restore from backup"
        echo "[7] Create backup"
        echo "[e] Exit"
        read -rp "Choice: " choice
        case $choice in
            1)
                scan_config_for_dotfiles
                stow_dotfiles
                ;;
            2)
                rollback_all
                ;;
            3)
                check_current_setup
                ;;
            4)
                setup_aliases
                ;;
            5)
                update_remote_repo
                ;;
            6)
                restore_backup
                ;;
            7)
                backup_file "$CONFIG_DIR"
                ;;
            e|E)
                echo "Goodbye! 👋"
                exit 0
                ;;
            *)
                echo "Invalid choice. Please try again."
                ;;
        esac
    else
        echo "✨ Welcome to your first Tush setup"
        setup_clean_home
        setup_dotfiles_repo
        scan_config_for_dotfiles
        stow_dotfiles
        setup_aliases
        echo "✅ Initial setup complete."
    fi
}

function print_banner() {
  cat << "EOF"
░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓███████▓▒░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░   ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░   ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░   ░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░░▒▓████████▓▒░ 
░▒▓█▓▒░   ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░   ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░    ░▒▓██████▓▒░░▒▓███████▓▒░░▒▓█▓▒░░▒▓█▓▒░ 

# 💠 Tush: Tersus Universal Shell Helper
EOF
  echo
}

function log_action() {
  echo "$1" | tee -a "$LOG_FILE"
}

function opth() {
    case "$1" in
        "--help"|"-h")
            echo "Usage: tush [options]"
            echo "Options:"
            echo "  -h, --help     Show this help message"
            echo "  -v, --version  Show version information"
            exit 0
            ;;
        "--version"|"-v")
            echo "Tush version 1.0.0"
            exit 0
            ;;
    esac
}

function load_or_init_config() {
  if [ ! -f "$CONFIG_FILE" ]; then
    print_banner
    echo "✨ Welcome to your first Tush setup. Let us get things initialized."
    prompt_dotfiles_path
    prompt_dry_run
    install_stow
    setup_clean_home
    stow_dotfiles
    setup_git_repo
    setup_aliases
    echo "✅ Initial setup complete."
  else
    source "$CONFIG_FILE"
    prompt_dry_run
  fi
}

function prompt_dotfiles_path() {
  read -rp "📁 Where do you keep your dotfiles repo? [default: ~/.dotfiles]: " USER_DOTFILES
  DOTFILES_DIR="${USER_DOTFILES:-$HOME/.dotfiles}"
  echo "DOTFILES_DIR=$DOTFILES_DIR" >> "$CONFIG_FILE"
  mkdir -p "$DOTFILES_DIR"
}

function prompt_dry_run() {
  DRY_RUN=false
  read -rp "🧪 Enable dry-run mode? (y/N): " dry_choice
  if [[ "$dry_choice" =~ ^[Yy]$ ]]; then
    DRY_RUN=true
    echo "⚠️  DRY-RUN ENABLED — No actions will be executed."
  fi
}

function install_stow() {
  echo "🔍 Checking for GNU Stow..."
  if ! command -v stow &>/dev/null; then
    echo "❌ GNU Stow not found. Installing..."
    if command -v pacman &>/dev/null; then
      sudo pacman -S --noconfirm stow
    elif command -v apt &>/dev/null; then
      sudo apt install -y stow
    elif command -v dnf &>/dev/null; then
      sudo dnf install -y stow
    elif command -v zypper &>/dev/null; then
      sudo zypper install -y stow
    else
      echo "Unsupported package manager."
      exit 1
    fi
  else
    echo "✅ GNU Stow is installed."
  fi
}

function setup_git_repo() {
  if [ ! -d "$DOTFILES_DIR/.git" ]; then
    cd "$DOTFILES_DIR"
    git init
    echo "# Dotfiles managed by Tush" > README.md
    git add . && git commit -m "Initial commit"
    echo "✅ Git repo initialized."
  fi
}

function setup_aliases() {
    # Determine shell and appropriate RC file
    case "$SHELL" in
        */bash)
            SHELL_RC="$HOME/.bashrc"
            ;;
        */zsh)
            SHELL_RC="$HOME/.zshrc"
            ;;
        */fish)
            SHELL_RC="$HOME/.config/fish/config.fish"
            ;;
        *)
            handle_error "Unsupported shell: $SHELL"
            ;;
    esac

    # Create RC file if it doesn't exist
    touch "$SHELL_RC" || handle_error "Failed to create $SHELL_RC"

    echo "🧩 Set aliases (or leave blank):"
    read -rp "Alias for this script [default: tush]: " alias1
    alias1="${alias1:-tush}"
    read -rp "Alias to cd clean home [default: tgh (acronym for tush go home)]: " alias2
    alias2="${alias2:-tgh}"
    read -rp "Alias to edit config [default: tec (acronym for touch edit config) ]: " alias3
    alias3="${alias3:-tec}"

    # Add aliases to RC file
    {
        echo "# Tush aliases"
        echo "alias $alias1='bash \"$CONFIG_DIR/tush.sh\"'"
        echo "alias $alias2='cd \"$CLEAN_HOME\"'"
        echo "alias $alias3='nvim \"$CONFIG_FILE\"'"
    } >> "$SHELL_RC"

    log_action "✅ Aliases added to $SHELL_RC"
    echo "🔁 Reload your shell to use them."
}

# Main execution
check_dependencies
opth "$1"
load_or_init_config
main_menu
