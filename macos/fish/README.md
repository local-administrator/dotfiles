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

#### gitgrabber — GitHub Organization Mirror
Mirrors a GitHub organization locally — clones new repos, pulls updates on existing ones.

**Features:**
- Clones new repos, fast-forward pulls on existing ones
- "What's new" commit summaries on updated repos
- Skips repos with dirty working trees (never touches uncommitted changes)
- Skips forks, archived, and empty repos by default
- Detects orphaned local repos no longer in the org
- Parallel execution (configurable worker count)
- Auto-fixes stale remote URLs
- HTTPS and SSH clone protocols
- Colorized output with emoji status indicators

**Prerequisites:** `gh` (GitHub CLI, authenticated via `gh auth login`), `python3`, `fzf` (for interactive mode)

**Usage:**
```fish
gitgrabber my-org                    # Preview changes, prompt to confirm
gitgrabber my-org -i                 # Pick repos with fzf multi-select
gitgrabber my-org -y                 # No prompts (scripting/cron)
gitgrabber my-org --dry-run          # Preview without changes
gitgrabber my-org --include-forks    # Include forked repos
gitgrabber my-org --include-archived # Include archived repos
gitgrabber my-org --protocol ssh     # Clone via SSH instead of HTTPS
gitgrabber my-org --jobs 8           # 8 parallel workers (default: 4)
gitgrabber my-org --quiet            # Only show changes and summary
```

**Output:**
```
  gitgrabber · my-org → ~/src/github.com/my-org/
  57 repos in org, 52 after filters

  📥 new-project — cloned
  🔄 active-repo — 3 new commit(s)
     · a1b2c3d fix token refresh logic
     · d4e5f6g add rate limit handling
  ✅ stable-lib — up to date
  ⚠️  wip-thing — skipped (dirty working tree)
  👻 old-thing — orphaned (not in org)

  Summary
  3 cloned · 1 updated · 48 current · 1 skipped · 1 orphaned
  Completed in 18s
```

| Flag | Short | Description |
|---|---|---|
| `--interactive` | `-i` | Pick repos with fzf multi-select |
| `--yes` | `-y` | Skip confirmation, run everything |
| `--dry-run` | `-n` | Preview actions without making changes |
| `--include-forks` | `-f` | Include forked repos (skipped by default) |
| `--include-archived` | `-a` | Include archived repos (skipped by default) |
| `--jobs N` | `-j N` | Max parallel jobs (default: 4) |
| `--protocol PROTO` | `-p PROTO` | Clone protocol: `https` (default) or `ssh` |
| `--quiet` | `-q` | Only show changes and summary |
| `--help` | `-h` | Show help |

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
│       ├── gitgrabber.fish        # GitHub org mirror/sync
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
