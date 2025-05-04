░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓███████▓▒░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░   ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░   ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░   ░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░░▒▓████████▓▒░ 
░▒▓█▓▒░   ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░   ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░    ░▒▓██████▓▒░░▒▓███████▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
                                              
# 💠 Tush: Tersus Universal Shell Helper

A powerful and flexible dotfiles management system that helps you maintain a clean home directory and manage your configuration files efficiently.

## 🌟 Features

- **Clean Home Management**: Organize your home directory with a modular structure
- **Dotfiles Management**: Manage configuration files using GNU Stow
- **Git Integration**: Version control your dotfiles with optional remote repository
- **Backup System**: Automatic backups before major changes
- **Rollback Support**: Easily undo changes and restore previous states
- **Cross-Shell Support**: Works with bash, zsh, and fish
- **Interactive Setup**: User-friendly interface for all operations
- **Dry Run Mode**: Preview changes before applying them

## 📋 Prerequisites

- GNU Stow
- Git
- A Unix-like operating system (Linux, macOS, etc.)
- One of the following package managers:
  - pacman (Arch Linux)
  - apt (Debian/Ubuntu)
  - dnf (Fedora)
  - zypper (openSUSE)

## 🚀 Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/tush.git
   ```

2. Make the script executable:
   ```bash
   chmod +x tush.sh
   ```

3. Run the script:
   ```bash
   ./tush.sh
   ```

## 🎯 Usage

### First Run

On first run, Tush will:
1. Set up a clean home directory
2. Create a dotfiles repository
3. Scan for existing configuration files
4. Set up symlinks without moving files
5. Optionally set up a remote repository
6. Create useful aliases

### Subsequent Runs

The main menu provides these options:
- Add new dotfiles
- Rollback changes
- Check current setup
- Manage aliases
- Update remote repository
- Restore from backup
- Create backup

### Managing Dotfiles

Tush uses GNU Stow to manage dotfiles, which means:
- Original files stay in place
- Symlinks are created automatically
- Easy to add/remove configurations
- Clean organization structure

### Backup and Restore

Tush automatically:
- Creates backups before major changes
- Stores backups in `~/.config/tersus/backups`
- Allows easy restoration of previous states
- Tracks all symlinks for clean rollback

## 🔧 Configuration

Configuration is stored in `~/.config/tersus/`:
- `tersus-home.conf`: Main configuration file
- `tush.log`: Operation log
- `README.md`: Generated documentation
- `symlinks.txt`: Symlink tracking
- `backups/`: Backup directory

## 🛠️ Customization

### Aliases

Tush sets up these aliases by default:
- `tush`: Run the Tush script
- `cdtersus`: Navigate to clean home
- `edittersus`: Edit Tush configuration

### Clean Home Structure

The clean home directory includes:
- Desktop
- Documents
- Downloads
- Music
- Pictures
- Public
- Templates
- Videos

## 🔄 Workflow

1. **Initial Setup**:
   ```bash
   ./tush.sh
   ```

2. **Add New Dotfiles**:
   - Run Tush
   - Select "Add new dotfiles"
   - Choose configurations to add

3. **Update Remote Repository**:
   - Run Tush
   - Select "Update remote repository"
   - Review changes
   - Commit and push

4. **Rollback Changes**:
   - Run Tush
   - Select "Rollback all changes"
   - Confirm rollback

## ⚠️ Safety Features

- Automatic backups before changes
- Dry run mode for previewing changes
- Symlink tracking for clean rollback
- Error handling and logging
- Dependency checking

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- GNU Stow for the dotfiles management system
- The Unix/Linux community for inspiration
- All contributors and users of Tush
