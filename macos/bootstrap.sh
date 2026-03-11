#!/bin/bash

# Bootstrap script for dotfiles on a fresh macOS machine.
# Usage: bash ~/.dotfiles/macos/bootstrap.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

DOTFILES_DIR="$HOME/.dotfiles"
META_DIR="$DOTFILES_DIR/macos"

step() { echo -e "\n${BLUE}==>${NC} $1"; }
ok()   { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
die()  { echo -e "${RED}✗${NC} $1"; exit 1; }

###############################################################################
# 1. Xcode Command Line Tools
###############################################################################
step "Checking Xcode Command Line Tools..."
if ! xcode-select -p &> /dev/null; then
  warn "Xcode CLT not found. Triggering install prompt..."
  xcode-select --install
  echo "Once the installer finishes, re-run this script."
  exit 0
fi
ok "Xcode CLT found"

###############################################################################
# 2. Homebrew
###############################################################################
step "Checking Homebrew..."
if ! command -v brew &> /dev/null; then
  warn "Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Load brew into the current shell session (Apple Silicon path)
  if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -f /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
else
  # Ensure brew is on PATH for the rest of this script
  if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi
ok "Homebrew ready"

###############################################################################
# 3. Dotfiles repo
###############################################################################
step "Checking dotfiles repo..."
if [ ! -d "$DOTFILES_DIR" ]; then
  echo -ne "${YELLOW}Dotfiles not found at $DOTFILES_DIR. Clone now?${NC} [Y/n]: "
  read -n 1 choice; echo ""
  if [[ "$choice" =~ ^[Nn]$ ]]; then
    die "Dotfiles required. Clone to $DOTFILES_DIR and re-run."
  fi
  read -p "Enter repo URL: " repo_url
  git clone "$repo_url" "$DOTFILES_DIR"
fi
ok "Dotfiles at $DOTFILES_DIR"

###############################################################################
# 4. Install packages (interactive Brewfile)
###############################################################################
step "Installing packages..."
bash "$META_DIR/brew_install.sh"

###############################################################################
# 5. Symlinks
###############################################################################
step "Creating symlinks..."
bash "$META_DIR/dotfile_setup.sh"

###############################################################################
# 5a. Mise trust + install
###############################################################################
step "Trusting and installing mise tools..."
if command -v mise &> /dev/null; then
  mise trust "$HOME/.config/mise/config.toml"
  ok "mise config trusted"
  if mise install; then
    ok "mise tools installed"
  else
    warn "mise install had errors — run 'mise install' manually to retry"
  fi
else
  warn "mise not found, skipping"
fi

###############################################################################
# 6. macOS defaults
###############################################################################
step "macOS defaults..."
echo -ne "${YELLOW}Apply macOS system defaults?${NC} [Y/n]: "
read -n 1 choice; echo ""
if [[ ! "$choice" =~ ^[Nn]$ ]]; then
  bash "$META_DIR/macos_setup.sh"
  ok "macOS defaults applied"
else
  warn "Skipped macOS defaults"
fi

###############################################################################
# 7. Fish as default shell
###############################################################################
step "Setting fish as default shell..."
FISH_PATH="/opt/homebrew/bin/fish"

if ! command -v fish &> /dev/null; then
  warn "fish not found, skipping shell change"
else
  if ! grep -qF "$FISH_PATH" /etc/shells; then
    echo "Adding fish to /etc/shells (requires sudo)..."
    echo "$FISH_PATH" | sudo tee -a /etc/shells > /dev/null
  fi

  if [ "$SHELL" != "$FISH_PATH" ]; then
    if chsh -s "$FISH_PATH"; then
      ok "Default shell set to fish"
    else
      warn "chsh failed — run manually after bootstrap: chsh -s $FISH_PATH"
    fi
  else
    ok "Fish is already the default shell"
  fi
fi

###############################################################################
# 8. Fisher plugins
###############################################################################
step "Installing fish plugins via Fisher..."
if command -v fish &> /dev/null; then
  fish -c "
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    fisher install jorgebucaran/fisher
    fisher update
  " && ok "Fisher plugins installed" || warn "Fisher install had errors — run 'fisher update' manually in fish"
else
  warn "fish not available, skipping Fisher bootstrap"
fi

###############################################################################
# Done
###############################################################################
echo -e "\n${GREEN}=== Bootstrap complete ===${NC}"
echo -e "Start a new shell: ${YELLOW}exec fish${NC}"
