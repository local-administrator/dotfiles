# Dotfiles

## 🚀 Quick Start

```bash
# clone repository
git clone https://github.com/local-administrator/dotfiles.git ~/.dotfiles

# run setup script to create symlinks
cd ~/.dotfiles/.dotfiles_meta
./dotfile_setup.sh

# install core tools + select applications interactively
# (core tools like fish, fzf, etc. are always installed)
./brew_install.sh

# configure macOS settings
./macos_setup.sh

# add fish to available shells
# set fish as default shell
echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/fish

# start fish shell
exec fish

# update all tools
update
```

## 📦 Components

### Terminal

#### Fish Shell

**Plugins (managed by Fisher):**
- **[z](https://github.com/jethrokuan/z)** - Directory jumping
- **[fzf.fish](https://github.com/patrickf1/fzf.fish)** - Fuzzy finder integration
- **[plugin-brew](https://github.com/oh-my-fish/plugin-brew)** - Homebrew integration
- **[sponge](https://github.com/meaningful-ooo/sponge)** - Clean command history
- **[autopair.fish](https://github.com/jorgebucaran/autopair.fish)** - Auto-complete pairs
- **[puffer-fish](https://github.com/nickeb96/puffer-fish)** - Text expansions (!, !!, ...)

**Custom Features:**
- CLI aliases (`bat`, `lsd`, `nvim`)
- Safe `rm` replacement using `trash`
- Vi key bindings
- Custom functions: `update`, `fullhistory`
- Custom greeting message: 🐟🐠🐡

#### Ghostty Terminal

**Configuration:**
- Theme: Catppuccin Macchiato
- Font: JetBrainsMono Nerd Font (14pt)
- Background: 85% opacity with blur
- Custom keybindings for pane navigation (Ctrl+h/j/k/l)
- Window padding: 10px
- Tab-style macOS titlebar

#### Starship Prompt

**Features:**
- Theme: Gruvbox Dark
- Git branch and status information
- Language version indicators (Ruby, Python, Go, Rust, etc.)
- Time display
- Directory listing with smart truncation
- Custom icons for various tools

### Command Line Tools

**File Management & Search:**
- `bat` - Cat replacement with syntax highlighting (Gruvbox Dark theme)
- `lsd` - Modern ls replacement
- `nnn` - Terminal file manager
- `trash` - Safe rm replacement
- `ripgrep` - Extremely fast grep alternative (rg)
- `fd` - Fast and user-friendly find alternative

**Development:**
- `lazygit` - Terminal UI for Git
- `gh` - GitHub CLI
- `fzf` - Fuzzy finder
- `mise` - Version manager for multiple runtimes
- `tmux` - Terminal multiplexer for session management
- `tree-sitter` - Incremental parsing library (for Neovim)

### Fonts
- Hack Nerd Font
- JetBrains Mono
- JetBrains Mono Nerd Font

### Symlinks Created
- `~/.config/fish` → Fish configuration
- `~/.config/ghostty` → Ghostty configuration
- `~/.config/nvim` → Neovim configuration
- `~/.config/zed` → Zed configuration
- `~/.config/bat` → Bat configuration
- `~/.config/starship.toml` → Starship configuration
- `~/.gitconfig` → Git configuration

## 🔄 Maintenance

### Update Command
The custom `update` function updates all package managers and tools:
```bash
update
```

Updates:
- Homebrew packages
- Mise-managed tools
- Fish plugins via Fisher
- Shows available macOS system updates

### Manual Updates
- Pull latest dotfiles: `git pull`
- Re-run setup: `./.dotfiles_meta/dotfile_setup.sh`
- Install new applications: `./.dotfiles_meta/brew_install.sh`
- Update macOS settings: `./.dotfiles_meta/macos_setup.sh`

## 🤝 Contributing

Feel free to fork and customize these dotfiles for your own use. If you find useful improvements, pull requests are welcome!
