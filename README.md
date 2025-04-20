░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓███████▓▒░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░   ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░   ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░   ░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░░▒▓████████▓▒░ 
░▒▓█▓▒░   ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░   ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░    ░▒▓██████▓▒░░▒▓███████▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
                                              
💠 Tush: Tersus Universal Shell Helper
--------------------------------------
Created by sonophage — for clarity, ritual, and shell-based serenity.
GitHub: https://github.com/sonophage/tersus-home
Tush creates a clean modular home in ~/tersus and manages your configs via GNU Stow.
Every action is tracked and reversible. Use it when you want your environment to breathe.

**Tush** is a modular shell script that manages a clean, deliberate, and reversible Linux home environment using GNU Stow.  
It was built to serve creators, minimalists, and neurodivergent thinkers who crave clarity, order, and control in their workspace.

---

## 🌌 The Meaning

### 🔹 Tersus
From Latin, meaning *clean*, *pure*, or *neat* — a guiding principle for this project.  
Tersus is the name of the curated home folder (`~/tersus` or a custom name) that acts as your **clean digital sanctuary**.

### 🔹 Tush
Short for **Tersus Universal Shell Helper** — and a little playful.  
`tush` is your command line companion to manage, update, and undo your clean home setup.

---

## 📁 What It Does

### 🛠 Core Features

- 🧠 **OS-aware**: installs GNU Stow if not found
- 🏡 **Creates a clean home** (`~/tersus`) with symlinks to `~/Documents`, `~/Downloads`, etc.
- 📂 **Moves & stows dotfiles** using GNU Stow (e.g. `fish`, `nvim`, `kitty`)
- 📝 **Tracks everything** in `~/.config/tersus/tersus-home.conf` and `tush.log`
- 🔗 **Injects a custom alias** into your shell to jump to your clean home
- 🔁 **Offers rollback & full reset** of all changes
- 🧑‍💻 **CLI-based or interactive menu** for flexibility and ease

---

## ⚙️ How It Works

1. Run `tush` with no arguments:
   - Asks you what to name your clean home
   - Creates symlinks from your original folders (e.g. `~/Documents`) to `~/tersus/Documents`
   - Displays available dotfiles in `~/.config` for selection
   - Moves selected dotfiles into `~/<clean-home>/.dotfiles/<name>/.config/<name>`
   - Uses `stow` to symlink them back
   - Logs all actions to a config file

2. On later runs, use:
   ```bash
   ./tush --add        # add new dotfiles to stow
   ./tush --rollback   # rollback all dotfiles
   ./tush --reset      # full teardown
   ./tush --alias      # show the shell alias for quick access
   ./tush --help       # usage guide
   ```
---

## 🐠 **How to make `tush` a real command in Fish (Its what I use)**

### ✅ 1. **Move the script somewhere permanent**
put the `tush.sh` script in a directory you control, like:

```bash
mkdir -p ~/.local/bin
mv /path/to/tush.sh ~/.local/bin/tush
chmod +x ~/.local/bin/tush
```

### ✅ 2. **Add that directory to your `$PATH`**
Fish uses a different way to handle `$PATH`.

To add `~/.local/bin` to your `PATH` **permanently** in Fish:

```fish
set -U fish_user_paths $fish_user_paths ~/.local/bin
```

> now you can run `tush` from anywhere.

---

### ✅ 3. (Optional) **Confirm it works**

```bash
which tush
```

should return:
```
~/.local/bin/tush
```

and then:
```bash
tush --help
```

should show your CLI menu.

---

## 📦 Example Setup

```bash
$ tush
📦 What should the name of your clean home directory be? tersus
📂 Available configs in ~/.config:
1  fish
2  nvim
3  kitty
Enter the names of the configs you want to stow (space-separated): fish nvim
🔗 What alias should be created? cdtersus
```

This creates:

```
~/.config/tersus/tersus-home.conf
~/tersus/
├── .dotfiles/
│   ├── fish/.config/fish/
│   └── nvim/.config/nvim/
├── Documents -> ~/Documents
├── Downloads -> ~/Downloads
...
```

---

## 🔐 Rollback & Reset

```bash
tush --rollback
```
Unstows all managed configs and moves them back to their original location.

```bash
tush --reset
```
Fully wipes your clean home, config, dotfiles, and logs. Offers a safety prompt.

---

## 📎 Logging

Every action is logged into:

- `~/.config/tersus/tersus-home.conf`
- `~/.config/tersus/tush.log`

You always know what happened and when.

---

## 🖤 Why It Was Created

This project was born from the need to **reclaim personal space** in Linux.  
Not just to dotfile — but to **ritualize the environment**.  
A home folder should feel like a sanctuary. Tush gives you a way to **build that sanctuary** — and remove it just as cleanly.
---

## 📄 License

MIT — share it, modify it, love it.
