#!/bin/bash

set -e

CONFIG_FILE="$HOME/.config/tersus_setup.conf"

function save_config() {
  mkdir -p "$(dirname $CONFIG_FILE)"
  echo "CLEAN_HOME=$CLEAN_HOME" > "$CONFIG_FILE"
  echo "DOTFILES=\"${DOTFILES[*]}\"" >> "$CONFIG_FILE"
}

function load_config() {
  if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    CONFIG_EXISTS=true
  else
    CONFIG_EXISTS=false
  fi
}

# Check OS and install stow
if ! command -v stow &> /dev/null; then
  echo '🛠️  Stow not found. Installing...'
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
      echo "❌ Unsupported Linux package manager. Please install stow manually."
      exit 1
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    brew install stow
  else
    echo "❌ Unsupported OS: $OSTYPE"
    exit 1
  fi
fi

# Load previous config
load_config

if $CONFIG_EXISTS; then
  echo "🔁 Previous setup detected:"
  echo "  - Clean home: $CLEAN_HOME"
  echo "  - Dotfiles: ${DOTFILES[*]}"
  read -rp "Would you like to add more dotfiles? (y/n): " ADD_MORE
else
  echo "Current HOME is: $HOME"
  read -rp 'What should the name of your clean home directory be (e.g., tersus)? ' CLEAN_HOME_NAME
  CLEAN_HOME="$HOME/$CLEAN_HOME_NAME"
  mkdir -p "$CLEAN_HOME/.dotfiles"

  # Create standard folders and symlinks
  for folder in Desktop Documents Downloads Music Pictures Public Templates Videos; do
    mkdir -p "$CLEAN_HOME/$folder"
    ln -sfn "$CLEAN_HOME/$folder" "$HOME/$folder"
  done

  read -rp 'Enter the names of the configs you want to stow (space-separated): ' -a DOTFILES
  save_config
fi

# If adding more dotfiles
if [ "$ADD_MORE" == "y" ]; then
  read -rp 'Enter new config folders to stow: ' -a NEW_DOTFILES
  DOTFILES+=("${NEW_DOTFILES[@]}")
  save_config
fi

# Process dotfiles
for name in "${DOTFILES[@]}"; do
  SRC="$HOME/.config/$name"
  DST="$CLEAN_HOME/.dotfiles/$name/.config/$name"
  if [ -d "$SRC" ]; then
    mkdir -p "$(dirname "$DST")"
    mv "$SRC" "$DST"
  else
    echo "⚠️  $SRC not found, skipping..."
  fi
  cd "$CLEAN_HOME/.dotfiles" && stow $name

done

echo '✨ Tersus setup complete.'
