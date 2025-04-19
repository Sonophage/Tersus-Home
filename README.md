
# Project: Tersus Home

**Tersus** — Latin for *clean*, *neat*, or *pure* — is a modular system for creating a minimal, version-controlled Linux `$HOME` environment using [GNU Stow](https://www.gnu.org/software/stow/).

Built for creators, neurodivergent users, and minimalists who value clarity over chaos.

---

## Structure

```
/home/yourname/tersus
├── .dotfiles/
│   ├── hypr/.config/hypr/
│   ├── kitty/.config/kitty/
│   └── ...
├── Documents/
├── Downloads/
├── Music/
├── Pictures/
├── Templates/
├── Videos/
├── Public/
└── Desktop/
```

All standard folders live inside your `tersus` directory and are symlinked to `$HOME` for compatibility.

---

## Features

- Auto-detects Linux/macOS
- Installs GNU Stow if missing
- Lets you choose your clean home name (default: `tersus`)
- Moves and stows dotfiles safely
- Supports re-running for future dotfile migrations

---

## Installation

```bash
git clone https://github.com/sonophage/tersus.git
cd tersus
chmod +x clean_homebase_setup.sh
./clean_homebase_setup.sh
```

---

## Reusable Workflow

You can run the script again anytime to move and stow additional config directories. It will only update what you give it.

---

## Stow Installer Logic

This script supports:

- `pacman`
- `apt`
- `dnf`
- `zypper`
- `brew` (macOS)

It installs stow if it's missing. Example logic:

```bash
if ! command -v stow &> /dev/null; then
  # OS-specific package manager install commands here
fi
```

---

## License

MIT — share it, remix it, keep it clean.
