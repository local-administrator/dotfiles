#!/bin/bash

# colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# config
DOTFILES_DIR="$HOME/.dotfiles"

# define all symlinks as source:target pairs
symlinks=(
  "macos/fish:$HOME/.config/fish"
  "macos/ghostty:$HOME/.config/ghostty"
  "nvim:$HOME/.config/nvim"
  "zed:$HOME/.config/zed"
  "bat:$HOME/.config/bat"
  "starship/starship.toml:$HOME/.config/starship.toml"
  "git/.gitconfig:$HOME/.gitconfig"
  "git/.gitignore:$HOME/.gitignore"
  "mise:$HOME/.config/mise"
)

# git local config setup
setup_git_local() {
  local gitconfig_local="$HOME/.gitconfig.local"

  if [ -f "$gitconfig_local" ]; then
    echo -e "${YELLOW}Git local config already exists:${NC} $gitconfig_local"
    read -p "Do you want to update it? (y/N): " update_git
    if [[ ! "$update_git" =~ ^[Yy]$ ]]; then
      return 0
    fi
  fi

  echo -e "${BLUE}Setting up device-specific git configuration...${NC}"
  read -p "Enter your git email for this device: " git_email

  cat > "$gitconfig_local" << EOF
# Device-specific git configuration
# This file is not tracked in version control
[user]
	email = $git_email
EOF

  echo -e "${GREEN}✓${NC} Git local config created with email: $git_email"
  return 0
}

setup_fish_local() {
  local fish_local="$HOME/.config/fish/config.local.fish"

  if [ -f "$fish_local" ]; then
    echo -e "${YELLOW}Fish local config already exists:${NC} $fish_local"
    return 0
  fi

  echo -e "${BLUE}Creating fish local config for device-specific settings...${NC}"
  cat > "$fish_local" << 'EOF'
# Device-specific fish configuration
# This file is not tracked in version control
# Add any machine-specific config here (e.g. work tools, local paths)
EOF

  echo -e "${GREEN}✓${NC} Fish local config created at $fish_local"
  return 0
}

check_dependencies() {
  local missing_deps=()

  echo -e "${BLUE}Checking dependencies...${NC}"

  # Check for required commands
  local commands=("fish" "git" "starship")
  for cmd in "${commands[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
      missing_deps+=("$cmd")
    else
      echo -e "${GREEN}✓${NC} $cmd found"
    fi
  done

  # Check for Homebrew
  if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}⚠${NC} Homebrew not found (recommended for installing dependencies)"
  else
    echo -e "${GREEN}✓${NC} Homebrew found"
  fi

  # Report missing dependencies (warn but don't block symlinks)
  if [ ${#missing_deps[@]} -gt 0 ]; then
    echo -e "${YELLOW}Missing dependencies:${NC} ${missing_deps[*]}"
    echo -e "${YELLOW}Install them with:${NC} brew install ${missing_deps[*]}"
    echo -e "${YELLOW}Or run interactive installer:${NC} $DOTFILES_DIR/macos/brew_install.sh"
  fi

  return 0
}

create_symlink() {
  local src="$1"
  local dst="$2"

  # Check if source exists
  if [ ! -e "$src" ]; then
    echo -e "${RED}Warning:${NC} Source does not exist: $src"
    return 1
  fi

  # Handle existing destination
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
      echo -e "${YELLOW}Already linked:${NC} $dst → $src"
      return 0
    fi
    echo -e "${YELLOW}Removing existing:${NC} $dst"
    rm -rf "$dst"
  fi

  # Create parent directory
  local parent_dir="$(dirname "$dst")"
  if [ ! -d "$parent_dir" ]; then
    echo -e "${YELLOW}Creating directory:${NC} $parent_dir"
    mkdir -p "$parent_dir"
  fi

  # Create the symlink
  echo -e "${GREEN}Linking:${NC} $src → $dst"
  ln -sf "$src" "$dst"
}

main() {
  echo -e "${BLUE}=== Dotfiles Setup ===${NC}"

  check_dependencies

  echo -e "\n${BLUE}Creating symlinks...${NC}"

  # Process all symlinks
  local success_count=0
  local total_count=${#symlinks[@]}

  for link in "${symlinks[@]}"; do
    src="$DOTFILES_DIR/${link%%:*}"
    dst="${link#*:}"
    if create_symlink "$src" "$dst"; then
      ((success_count++))
    fi
  done

  echo -e "\n${GREEN}=== Setup Complete ===${NC}"
  echo -e "Linked $success_count/$total_count configurations"

  # Setup local configs
  echo ""
  setup_git_local
  setup_fish_local

}

main "$@"
