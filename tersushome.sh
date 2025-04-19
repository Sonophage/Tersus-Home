#!/bin/bash

set -e

echo '🌱 Welcome to the Tersus Home Setup Script'

# Detect operating system
OS=$(uname -s)
echo "Detected OS: $OS"

# Check if GNU Stow is installed
if ! command -v stow &> /dev/null; then
    echo '❌ GNU Stow is not installed. Please install it and rerun this script.'
    exit 1
fi

# Ask for current and new home directory
CURRENT_HOME=$HOME
echo "Current HOME is: $CURRENT_HOME"
read -rp 'What should the name of your clean home directory be (e.g., tersus)? ' CLEAN_HOME_NAME
CLEAN_HOME="$CURRENT_HOME/$CLEAN_HOME_NAME"
echo "Creating clean home at: $CLEAN_HOME"
mkdir -p "$CLEAN_HOME/.dotfiles"

# Create default user directories inside new clean home
for folder in Desktop Documents Downloads Music Pictures Public Templates Videos; do
    mkdir -p "$CLEAN_HOME/$folder"
    ln -sfn "$CLEAN_HOME/$folder" "$CURRENT_HOME/$folder"
done

# Ask which dotfiles to move
echo 'These are the current config directories in ~/.config:'
ls -1 "$CURRENT_HOME/.config"
read -rp 'Enter the names of the configs you want to stow (separated by space): ' -a DOTFILES

# Move dotfiles and prepare for stow
for name in "${DOTFILES[@]}"; do
    SRC="$CURRENT_HOME/.config/$name"
    DST="$CLEAN_HOME/.dotfiles/$name/.config/$name"
    if [ -d "$SRC" ]; then
        mkdir -p "$(dirname "$DST")"
        mv "$SRC" "$DST"
    else
        echo "⚠️  $SRC not found, skipping..."
    fi
done

# Stow configs
cd "$CLEAN_HOME/.dotfiles"
for name in "${DOTFILES[@]}"; do
    stow $name
done

# Check for re-run and prompt for new dotfiles
echo
echo '✅ Initial setup complete. You can rerun this script to add more dotfiles later.'
read -rp 'Would you like to stow additional dotfiles now? (y/n): ' ANSWER
if [[ "$ANSWER" =~ ^[Yy]$ ]]; then
    read -rp 'Enter the new config names to stow: ' -a NEW_DOTFILES
    for name in "${NEW_DOTFILES[@]}"; do
        SRC="$CURRENT_HOME/.config/$name"
        DST="$CLEAN_HOME/.dotfiles/$name/.config/$name"
        if [ -d "$SRC" ]; then
            mkdir -p "$(dirname "$DST")"
            mv "$SRC" "$DST"
        else
            echo "⚠️  $SRC not found, skipping..."
        fi
        cd "$CLEAN_HOME/.dotfiles" && stow $name
    done
fi

echo '✨ Done. Your clean homebase is ready.'
