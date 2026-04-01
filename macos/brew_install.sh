#!/bin/bash

# Interactive Brew Bundle Installer
# Automatically installs core tools, allows selection of applications

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DOTFILES_DIR="$HOME/.dotfiles"
BREWFILE="$DOTFILES_DIR/macos/Brewfile"
TEMP_BREWFILE="/tmp/selected_brewfile"

# Check if Homebrew is installed
check_homebrew() {
  if ! command -v brew &> /dev/null; then
    echo -e "${RED}Error:${NC} Homebrew not found. Please install it first:"
    echo -e "  ${YELLOW}/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"${NC}"
    exit 1
  fi
}

# Parse applications from Brewfile
get_applications() {
  grep '^cask ' "$BREWFILE" | grep -v '^cask "font-' | sed 's/cask "\([^"]*\)".*/\1/' | sort
}

# Parse fonts from Brewfile  
get_fonts() {
  grep '^cask "font-' "$BREWFILE" | sed 's/cask "\([^"]*\)".*/\1/' | sort
}

# Compatible array reading function
read_into_array() {
  local arr_name=$1
  local input_source=$2
  eval "$arr_name=()"
  while IFS= read -r line; do
    [[ -n "$line" ]] && eval "$arr_name+=(\"$line\")"
  done < <($input_source)
}

# Create core tools Brewfile (everything except applications)
create_core_brewfile() {
  echo "# Core tools (auto-installed)" > "$TEMP_BREWFILE"
  grep '^brew ' "$BREWFILE" >> "$TEMP_BREWFILE"
  echo "" >> "$TEMP_BREWFILE"
}

# Interactive application selection using fzf
select_applications() {
  local apps=()
  read_into_array apps get_applications

  if [ ${#apps[@]} -eq 0 ]; then
    echo -e "${YELLOW}No applications found in Brewfile${NC}"
    return
  fi

  # Split into already-installed and not-yet-installed
  local installed_casks
  installed_casks=$(brew list --cask 2>/dev/null)

  local installed_apps=()
  local new_apps=()
  for app in "${apps[@]}"; do
    if echo "$installed_casks" | grep -qx "$app"; then
      installed_apps+=("$app")
    else
      new_apps+=("$app")
    fi
  done

  # Auto-include already-installed apps without prompting
  if [ ${#installed_apps[@]} -gt 0 ]; then
    echo "# Applications (already installed)" >> "$TEMP_BREWFILE"
    for app in "${installed_apps[@]}"; do
      echo "cask \"$app\"" >> "$TEMP_BREWFILE"
    done
    echo "" >> "$TEMP_BREWFILE"
    echo -e "${GREEN}✓${NC} ${#installed_apps[@]} applications already installed"
  fi

  # If nothing new to install, skip the picker
  if [ ${#new_apps[@]} -eq 0 ]; then
    return
  fi

  # Check if fzf is available, install core tools if needed
  if ! command -v fzf &> /dev/null; then
    echo -e "${YELLOW}fzf not found. Installing core tools first...${NC}"
    brew bundle install --file="$TEMP_BREWFILE"
    echo -e "${GREEN}✓${NC} Core tools installed"
    echo ""
  fi

  # If fzf is still not available, fall back to installing all new apps
  if ! command -v fzf &> /dev/null; then
    echo -e "${YELLOW}fzf still not available. Installing all ${#new_apps[@]} new applications...${NC}"
    echo "# All new applications" >> "$TEMP_BREWFILE"
    for app in "${new_apps[@]}"; do
      echo "cask \"$app\"" >> "$TEMP_BREWFILE"
    done
    return
  fi

  echo -e "\n${BLUE}=== New Applications ===${NC}"
  echo -e "Use TAB to select/deselect, ENTER to confirm, ctrl-a to select all:"
  echo ""

  local app_list="/tmp/brew_apps_$$"
  printf '%s\n' "${new_apps[@]}" > "$app_list"

  local selected_apps
  selected_apps=$(cat "$app_list" | fzf \
    --multi \
    --bind 'ctrl-a:select-all' \
    --bind 'ctrl-d:deselect-all' \
    --header 'TAB: select/deselect | ctrl-a: select all | ctrl-d: deselect all | ENTER: confirm' \
    --preview-window=hidden \
    --height=60% \
    --border)

  rm -f "$app_list"

  if [ -n "$selected_apps" ]; then
    echo "# Selected Applications" >> "$TEMP_BREWFILE"
    while IFS= read -r app; do
      echo "cask \"$app\"" >> "$TEMP_BREWFILE"
    done <<< "$selected_apps"
    echo "" >> "$TEMP_BREWFILE"
    local count=$(echo "$selected_apps" | wc -l | tr -d ' ')
    echo -e "\n${GREEN}Selected $count new applications${NC}"
  else
    echo -e "\n${YELLOW}No new applications selected${NC}"
  fi
}

# Font selection
select_fonts() {
  local fonts=()
  read_into_array fonts get_fonts

  if [ ${#fonts[@]} -eq 0 ]; then
    return
  fi

  # Split into already-installed and new
  local installed_casks
  installed_casks=$(brew list --cask 2>/dev/null)

  local installed_fonts=()
  local new_fonts=()
  for font in "${fonts[@]}"; do
    if echo "$installed_casks" | grep -qx "$font"; then
      installed_fonts+=("$font")
    else
      new_fonts+=("$font")
    fi
  done

  # Auto-include already-installed fonts
  if [ ${#installed_fonts[@]} -gt 0 ]; then
    echo "# Fonts (already installed)" >> "$TEMP_BREWFILE"
    for font in "${installed_fonts[@]}"; do
      echo "cask \"$font\"" >> "$TEMP_BREWFILE"
    done
    echo "" >> "$TEMP_BREWFILE"
    echo -e "${GREEN}✓${NC} ${#installed_fonts[@]} fonts already installed"
  fi

  if [ ${#new_fonts[@]} -eq 0 ]; then
    return
  fi

  echo -e "\n${BLUE}=== Font Selection ===${NC}"
  echo -ne "${YELLOW}Install ${#new_fonts[@]} new font(s)?${NC} [Y/n]: "
  read -n 1 choice
  echo ""

  if [[ ! "$choice" =~ ^[Nn]$ ]]; then
    echo "# Fonts" >> "$TEMP_BREWFILE"
    for font in "${new_fonts[@]}"; do
      echo "cask \"$font\"" >> "$TEMP_BREWFILE"
    done
    echo -e "${GREEN}✓${NC} Added ${#new_fonts[@]} new fonts"
  else
    echo -e "${RED}✗${NC} Skipped new fonts"
  fi
}

# Install using temp Brewfile
install_selected() {
  if [ ! -f "$TEMP_BREWFILE" ]; then
    echo -e "${RED}Error:${NC} No selection made"
    return 1
  fi

  echo -e "\n${BLUE}=== Installation Summary ===${NC}"
  echo -e "${YELLOW}Will install:${NC}"
  cat "$TEMP_BREWFILE"
  echo ""

  echo -ne "${YELLOW}Proceed with installation?${NC} [Y/n]: "
  read -n 1 choice
  echo ""

  if [[ "$choice" =~ ^[Nn]$ ]]; then
    echo -e "${YELLOW}Installation cancelled${NC}"
    return 0
  fi

  echo -e "\n${BLUE}Installing selected packages...${NC}"
  brew bundle install --file="$TEMP_BREWFILE"
  
  local exit_code=$?
  if [ $exit_code -eq 0 ]; then
    echo -e "\n${GREEN}✓ Installation completed successfully!${NC}"
  else
    echo -e "\n${RED}✗ Installation completed with errors${NC}"
  fi

  return $exit_code
}

# Cleanup
cleanup() {
  rm -f "$TEMP_BREWFILE"
}

# Main function
main() {
  echo -e "${BLUE}=== Interactive Brew Bundle Installer ===${NC}"
  
  # Check dependencies
  check_homebrew
  
  if [ ! -f "$BREWFILE" ]; then
    echo -e "${RED}Error:${NC} Brewfile not found at $BREWFILE"
    exit 1
  fi

  # Setup trap for cleanup
  trap cleanup EXIT

  # Create base Brewfile with core tools
  create_core_brewfile
  echo -e "${GREEN}✓${NC} Core tools will be auto-installed"

  # Interactive selections
  select_applications
  select_fonts

  # Install everything
  install_selected
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi