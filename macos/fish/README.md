# Fish Shell Configuration

This directory contains custom Fish shell configuration, functions, themes, and plugins.

## Features

### 🎯 Custom Functions

#### Full History - Complete Command Logging
The `fullhistory` function provides complete, timestamped command logging that preserves ALL commands (including duplicates) unlike Fish's default history which deduplicates entries.

**Features:**
- Complete logging with timestamps (no deduplication)
- Multiple timezones (Pacific and UTC)
- Monthly log rotation with 4-month retention
- Markdown export formats (defaults to last 7 days)
- Persistent storage in `~/.local/share/fish/fullhistory/`

**Usage:**
```fish
fullhistory          # Show last 50 commands with timestamps
fullhistory 100      # Show last 100 commands
fullhistory -e       # Export last 7 days to simple markdown
fullhistory -ed      # Export last 7 days to detailed markdown (grouped by day)
```

#### Update Command
Updates all package managers and tools:
```fish
update               # Updates Homebrew, mise, Fish plugins, and checks macOS updates
```

#### Application Shortcuts
- `subl` - Opens Sublime Text
- `cursor` - Opens Cursor editor in current directory

### 🔤 Aliases & Abbreviations

#### Enhanced Commands
- `cat` → `bat` (better cat with syntax highlighting)
- `ls` → `lsd` (better ls with icons and colors)
- `vim` → `nvim` (Neovim)
- `rm` → `trash` (safer rm that moves to trash instead of deleting)

### 🐠 Custom Greeting
Random fish emoji greeting on shell startup (🐟, 🐠, 🐡, 🐳, 🦈)

### 🎨 Themes
Four Tokyo Night color themes available:
- `tokyonight_day.theme`
- `tokyonight_moon.theme`
- `tokyonight_night.theme`
- `tokyonight_storm.theme`

### 📦 Plugins (via Fisher)
- **z** - Jump to directories with frecency tracking
- **fzf.fish** - Fuzzy finder integration for Fish
- **brew** - Homebrew completions and utilities
- **sponge** - Clean command history automatically
- **autopair.fish** - Auto-close brackets, quotes, etc.
- **puffer-fish** - Text expansions (!!, !$, ... → ../..)

## File Structure

```
fish/
├── config.fish              # Main configuration file
├── fish_plugins            # Fisher plugin list
├── fish_variables          # Fish universal variables
├── completions/            # Command completions
├── conf.d/                 # Configuration snippets
│   └── custom/
│       ├── abbrs.fish      # Abbreviations
│       ├── aliases.fish    # Function-based aliases
│       ├── autopair.fish   # Autopair config
│       └── fullhistory_init.fish  # History logging setup
├── functions/              # Fish functions
│   └── custom/
│       ├── fish_greeting.fish     # Custom greeting
│       ├── fullhistory.fish       # Main history function
│       ├── fullhistory_logger.fish # History logging hook
│       ├── sublime.fish          # Sublime Text launcher
│       └── update.fish          # System updater
└── themes/                 # Color themes
```

## Configuration Details

### Environment Variables
- `EDITOR`: nvim
- `VISUAL`: nvim
- `PAGER`: less
- `MANPAGER`: bat with man page highlighting
- Vi mode keybindings enabled

### Integration
- Homebrew environment initialization
- fzf integration
- Starship prompt

## Installation

1. Ensure Fish shell is installed: `brew install fish`
2. Install Fisher plugin manager: https://github.com/jorgebucaran/fisher
3. Install dependencies:
   ```fish
   brew install bat lsd trash nvim fzf starship
   ```
4. Source the configuration:
   ```fish
   source ~/.dotfiles/fish/config.fish
   ```
5. Install plugins:
   ```fish
   fisher update
   ```

## Log Files
- `~/.local/share/fish/fullhistory/history_YYYY-MM.log` - Monthly command history logs (kept for 4 months)

## Notes
- Commands are logged in real-time via the `fish_postexec` event
- The `rm` abbreviation requires `trash` to be installed for safety
- Old logs are automatically cleaned up after 4 months
