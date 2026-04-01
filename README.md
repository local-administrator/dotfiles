# Dotfiles

## 🚀 Quick Start

### macOS
```bash
git clone https://github.com/local-administrator/dotfiles.git ~/.dotfiles
bash ~/.dotfiles/macos/bootstrap.sh
exec fish
update
```

### Windows
```powershell
git clone https://github.com/local-administrator/dotfiles.git ~/.dotfiles
pwsh -ExecutionPolicy Bypass -File ~/.dotfiles/windows/bootstrap.ps1
nu
```

## 📦 Components

### Terminal

#### Fish Shell (macOS)

**Plugins (managed by Fisher):**
- **[fzf.fish](https://github.com/patrickf1/fzf.fish)** — Fuzzy finder integration
- **[plugin-brew](https://github.com/oh-my-fish/plugin-brew)** — Homebrew integration
- **[sponge](https://github.com/meaningful-ooo/sponge)** — Clean command history
- **[autopair.fish](https://github.com/jorgebucaran/autopair.fish)** — Auto-complete pairs
- **[puffer-fish](https://github.com/nickeb96/puffer-fish)** — Text expansions (!, !!, ...)

**Custom Features:**
- CLI abbreviations (`bat`, `lsd`, `nvim`, `trash`, `lazygit`)
- Vi key bindings
- Custom functions: `update`, `fullhistory`, `curlcheck`, `cbash`
- Custom greeting: 🐟🐠🐡🐳🦈

#### Nushell (Windows)
- Vi edit mode, fuzzy completions, SQLite history
- Abbreviations mirroring macOS setup
- Starship, zoxide, mise integration

#### Ghostty Terminal
- Theme: Catppuccin Macchiato
- Font: JetBrainsMono Nerd Font (14pt)
- 85% opacity with blur
- Pane navigation: Ctrl+h/j/k/l

#### Starship Prompt
- Theme: Gruvbox Dark
- Git branch/status, language versions, time display

### Command Line Tools

| Tool | Description |
|------|-------------|
| `bat` | Cat replacement with syntax highlighting |
| `delta` | Git diff viewer with syntax highlighting |
| `fd` | Fast find alternative |
| `fzf` | Fuzzy finder |
| `gh` | GitHub CLI |
| `lazygit` | Terminal UI for Git |
| `lsd` | Modern ls replacement |
| `mise` | Runtime version manager |
| `nnn` | Terminal file manager |
| `ripgrep` | Extremely fast grep (rg) |
| `starship` | Cross-shell prompt |
| `tmux` | Terminal multiplexer |
| `trash` | Safe rm replacement |
| `zoxide` | Smart directory jumping (z) |
| `duti` | Default file association manager |

### macOS System Defaults

Applied via `macos/macos_setup.sh`:

- **Appearance:** Dark mode, pink accent/highlight
- **Finder:** List view, show hidden files, all extensions, status bar, POSIX path in title
- **Dock:** Auto-hide (instant), bottom, no default apps, genie effect
- **Trackpad:** Tap to click
- **Keyboard:** Fast key repeat, no autocorrect/substitutions
- **Hot corners:** Top-left Mission Control, bottom-left Lock Screen
- **Screenshots:** Save to `~/Screenshots`, PNG, no shadow
- **Menu bar:** Bluetooth and Sound always visible
- **Spotlight:** Cmd+Space disabled (for Raycast)
- **Speed:** No window animations, fast Mission Control, instant resize

### File Associations

Managed via `duti` — sets Zed as the default editor for text, code, script, web, and config files.

## 🔗 Symlinks

### macOS
```
~/.config/fish          → dotfiles/macos/fish
~/.config/ghostty       → dotfiles/macos/ghostty
~/.config/nvim          → dotfiles/nvim
~/.config/zed           → dotfiles/zed
~/.config/bat           → dotfiles/bat
~/.config/mise          → dotfiles/mise
~/.config/starship.toml → dotfiles/starship/starship.toml
~/.gitconfig            → dotfiles/git/.gitconfig
~/.gitignore            → dotfiles/git/.gitignore
```

### Windows
```
%APPDATA%\nushell\      → dotfiles/windows/nushell/*
%LOCALAPPDATA%\nvim     → dotfiles/nvim
%APPDATA%\bat           → dotfiles/bat
%APPDATA%\Zed\          → dotfiles/zed/settings.json
%USERPROFILE%\.config\  → dotfiles/starship, dotfiles/mise
%USERPROFILE%\.gitconfig → dotfiles/git/.gitconfig
%USERPROFILE%\.gitignore → dotfiles/git/.gitignore
```

## 📁 Local Config (Device-Specific)

These files are gitignored and created during setup:

| File | Purpose |
|------|---------|
| `~/.gitconfig.local` | Email, signing keys, work tool integrations |
| `~/.config/fish/config.local.fish` | Work tools, local PATH, machine-specific config |
| `~/.config/nushell/config.local.nu` | Windows device-specific config |

## 🔄 Maintenance

### Update Everything
```fish
update    # Homebrew, mise, Fisher plugins, macOS system updates
```

### Manual Operations
```bash
bash macos/dotfile_setup.sh    # Re-create symlinks
bash macos/brew_install.sh     # Install new packages
bash macos/macos_setup.sh      # Re-apply macOS defaults
bash macos/duti_setup.sh       # Re-apply file associations
git pull                       # Pull latest dotfiles
```

## 🤝 Contributing

Feel free to fork and customize these dotfiles for your own use. If you find useful improvements, pull requests are welcome!
