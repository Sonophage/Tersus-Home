#!/bin/bash

set -e

CONFIG_DIR="$HOME/.config/tersus"
CONFIG_FILE="$CONFIG_DIR/tersus-home.conf"
LOG_FILE="$CONFIG_DIR/tush.log"

mkdir -p "$CONFIG_DIR"

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
# --------------------------------------
# Created by cvltik — for clarity, ritual, and shell-based serenity.
# GitHub: https://github.com/sonophage/tush
# Tush creates a clean modular home in ~/tersus and manages your configs via GNU Stow.
# Every action is tracked and reversible. Use it when you want your environment to breathe.
EOF
  echo
}

print_banner

CONFIG_DIR="$HOME/.config/tersus"
CONFIG_FILE="$CONFIG_DIR/tersus-home.conf"
LOG_FILE="$CONFIG_DIR/tush.log"

mkdir -p "$CONFIG_DIR"

function log_action() {
  echo "$1" | tee -a "$LOG_FILE"
}

function install_stow() {
  echo "🔍 Checking for GNU Stow..."
  if ! command -v stow &>/dev/null; then
    echo "❌ GNU Stow not found. Installing..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
      if command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm stow
      elif command -v apt &>/dev/null; then
        sudo apt install -y stow
      elif command -v dnf &>/dev/null; then
        sudo dnf install -y stow
      elif command -v zypper &>/dev/null; then
        sudo zypper install -y stow
      else
        echo "Unsupported package manager. Please install stow manually."
        exit 1
      fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
      brew install stow
    else
      echo "Unsupported OS: $OSTYPE"
      exit 1
    fi
  else
    echo "✅ GNU Stow is installed."
  fi
}

function setup_clean_home() {
  read -rp "📦 What should the name of your clean home directory be? " CLEAN_HOME_NAME
  CLEAN_HOME="$HOME/$CLEAN_HOME_NAME"
  mkdir -p "$CLEAN_HOME/.dotfiles"
  echo "CLEAN_HOME=$CLEAN_HOME" > "$CONFIG_FILE"
  log_action "Created clean home: $CLEAN_HOME"

  for folder in Desktop Documents Downloads Music Pictures Public Templates Videos; do
    TARGET="$HOME/$folder"
    LINK="$CLEAN_HOME/$folder"
    if [ -d "$TARGET" ]; then
      ln -sfn "$TARGET" "$LINK"
      log_action "ln -sfn $TARGET $LINK"
    fi
  done
}

function list_dotfiles() {
  echo "📂 Available configs in ~/.config:"
  mapfile -t DOTFILES_LIST < <(ls -1 ~/.config)
  for i in "${!DOTFILES_LIST[@]}"; do
    printf "[%2d] %s\n" "$((i+1))" "${DOTFILES_LIST[$i]}"
  done

  echo
  read -rp "Select dotfiles to stow by number (space-separated): " -a SELECTIONS
  DOTFILES=()
  for i in "${SELECTIONS[@]}"; do
    INDEX=$((i-1))
    if [[ -n "${DOTFILES_LIST[$INDEX]}" ]]; then
      DOTFILES+=("${DOTFILES_LIST[$INDEX]}")
    fi
  done

  echo "DOTFILES=("${DOTFILES[@]}")" >> "$CONFIG_FILE"
}

function stow_dotfiles() {
  list_dotfiles
  for name in "${DOTFILES[@]}"; do
    SRC="$HOME/.config/$name"
    DST="$CLEAN_HOME/.dotfiles/$name/.config/$name"
    mkdir -p "$(dirname "$DST")"
    mv "$SRC" "$DST"
    (cd "$CLEAN_HOME/.dotfiles" && stow "$name")
    log_action "mv $SRC → $DST && stow $name"
  done
}

function add_alias() {
  read -rp "🔗 What alias should be created for accessing your clean home? (e.g., cdtersus): " ALIAS_NAME
  ALIAS_LINE="alias $ALIAS_NAME='cd $CLEAN_HOME'"

  echo "ALIAS_NAME=$ALIAS_NAME" >> "$CONFIG_FILE"
  echo "ALIAS_LINE="$ALIAS_LINE"" >> "$CONFIG_FILE"

  SHELL_NAME=$(basename "$SHELL")
  case "$SHELL_NAME" in
    zsh) echo "$ALIAS_LINE" >> "$HOME/.zshrc" ;;
    bash) echo "$ALIAS_LINE" >> "$HOME/.bashrc" ;;
    fish) echo "alias $ALIAS_NAME 'cd $CLEAN_HOME'" >> "$HOME/.config/fish/config.fish" ;;
    *) echo "Could not detect supported shell for alias injection." ;;
  esac
  log_action "Alias $ALIAS_NAME added to $SHELL_NAME config."
}

function show_alias() {
  grep "^ALIAS_LINE=" "$CONFIG_FILE" | cut -d '=' -f2-
}

function rollback_all() {
  source "$CONFIG_FILE"
  for name in "${DOTFILES[@]}"; do
    echo "🔄 Unstowing $name..."
    (cd "$CLEAN_HOME/.dotfiles" && stow -D "$name")
    SRC="$CLEAN_HOME/.dotfiles/$name/.config/$name"
    DST="$HOME/.config/$name"
    if [ -d "$SRC" ]; then
      mv "$SRC" "$DST"
      log_action "Rollback: mv $SRC → $DST"
    fi
  done
}

function reset_tersus() {
  source "$CONFIG_FILE"
  echo "⚠️  This will remove all symlinks, dotfiles, and your clean home directory."
  read -rp "Are you sure? (y/N): " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    rollback_all
    rm -rf "$CLEAN_HOME"
    rm -f "$CONFIG_FILE"
    rm -f "$LOG_FILE"
    echo "🗑️  Clean home and config removed."
  else
    echo "❌ Reset aborted."
  fi
}

function print_help() {
  echo "Usage: tush [--add] [--rollback] [--alias] [--reset]"
  echo "  --add           Add new dotfiles to stow"
  echo "  --rollback      Undo all stowed dotfiles"
  echo "  --alias         Show the shell alias for cdting into the clean home"
  echo "  --reset         Fully remove all symlinks and delete the clean home"
  echo "  No args         Launch interactive menu"
}

case "$1" in
  --add) install_stow; source "$CONFIG_FILE"; stow_dotfiles ;;
  --rollback) rollback_all ;;
  --alias) show_alias ;;
  --reset) reset_tersus ;;
  ""|--menu) install_stow; setup_clean_home; stow_dotfiles; add_alias ;;
  --help|-h) print_help ;;
  *) echo "Unknown option: $1"; print_help ;;
esac
