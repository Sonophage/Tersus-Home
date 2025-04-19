
#!/bin/bash

set -e

CONFIG_FILE="$HOME/.config/tersus_setup.conf"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ No Tersus config found. Cannot roll back."
  exit 1
fi

source "$CONFIG_FILE"

echo "🚨 Rolling back Tersus setup..."
echo "  Clean home: $CLEAN_HOME"
echo "  Dotfiles: ${DOTFILES[*]}"

# Unstow dotfiles
cd "$CLEAN_HOME/.dotfiles"
for name in "${DOTFILES[@]}"; do
  echo "🔄 Unstowing $name"
  stow -D "$name"
  SRC="$CLEAN_HOME/.dotfiles/$name/.config/$name"
  DST="$HOME/.config/$name"
  if [ -d "$SRC" ]; then
    echo "↩️  Moving $SRC → $DST"
    mkdir -p "$(dirname "$DST")"
    mv "$SRC" "$DST"
  fi
done

# Remove standard folder symlinks and recreate as real folders
for folder in Desktop Documents Downloads Music Pictures Public Templates Videos; do
  TARGET="$HOME/$folder"
  if [ -L "$TARGET" ]; then
    echo "🧹 Removing symlink: $TARGET"
    rm "$TARGET"
    mkdir -p "$TARGET"
  fi
done

echo "🧼 Done. Your system has been rolled back to pre-Tersus state."
read -rp "Do you want to remove the Tersus directory ($CLEAN_HOME)? (y/n): " ANSWER
if [[ "$ANSWER" =~ ^[Yy]$ ]]; then
  rm -rf "$CLEAN_HOME"
  echo "🗑️  Removed $CLEAN_HOME"
fi
