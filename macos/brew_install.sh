#!/bin/bash

# Interactive Brew Bundle Installer
# Core tools (formulae) install automatically via brew bundle.
# Applications (casks) are presented interactively — only net-new shown.

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

DOTFILES_DIR="$HOME/.dotfiles"
BREWFILE="$DOTFILES_DIR/macos/Brewfile"
TEMP_BREWFILE="/tmp/selected_brewfile"

check_homebrew() {
  if ! command -v brew &> /dev/null; then
    echo -e "${RED}Error:${NC} Homebrew not found. Please install it first:"
    echo -e "  ${YELLOW}/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"${NC}"
    exit 1
  fi
}

# Interactive application selection — only shows what's not installed
select_applications() {
  local installed_casks
  installed_casks=$(brew list --cask 2>/dev/null)

  # Find casks in Brewfile that aren't installed (exclude fonts)
  local new_apps=()
  while IFS= read -r app; do
    [[ -z "$app" ]] && continue
    if ! echo "$installed_casks" | grep -qx "$app"; then
      new_apps+=("$app")
    fi
  done < <(grep '^cask ' "$BREWFILE" | grep -v '^cask "font-' | sed 's/cask "\([^"]*\)".*/\1/' | sort)

  if [ ${#new_apps[@]} -eq 0 ]; then
    echo -e "${GREEN}✓${NC} All applications already installed"
    return
  fi

  # Ensure fzf is available — install formulae first if needed
  if ! command -v fzf &> /dev/null; then
    echo -e "${YELLOW}fzf not available. Installing formulae first...${NC}"
    grep '^brew ' "$BREWFILE" > "$TEMP_BREWFILE"
    brew bundle install --file="$TEMP_BREWFILE" --no-upgrade
    echo ""
  fi

  # Fallback if fzf still not available
  if ! command -v fzf &> /dev/null; then
    echo -e "${YELLOW}fzf not available. Adding all ${#new_apps[@]} new applications...${NC}"
    for app in "${new_apps[@]}"; do
      echo "cask \"$app\"" >> "$TEMP_BREWFILE"
    done
    return
  fi

  echo -e "\n${BLUE}=== ${#new_apps[@]} New Application(s) ===${NC}"

  local selected_apps
  selected_apps=$(printf '%s\n' "${new_apps[@]}" | fzf \
    --multi \
    --bind 'ctrl-a:select-all' \
    --bind 'ctrl-d:deselect-all' \
    --header 'TAB: select | ctrl-a: all | ctrl-d: none | ESC: skip | ENTER: confirm' \
    --preview-window=hidden \
    --height=60% \
    --border) || true

  if [ -n "$selected_apps" ]; then
    while IFS= read -r app; do
      echo "cask \"$app\"" >> "$TEMP_BREWFILE"
    done <<< "$selected_apps"
    local count=$(echo "$selected_apps" | wc -l | tr -d ' ')
    echo -e "${GREEN}Selected $count application(s)${NC}"
  else
    echo -e "${YELLOW}Skipped application selection${NC}"
  fi
}

# Font selection — only shows what's not installed
select_fonts() {
  local installed_casks
  installed_casks=$(brew list --cask 2>/dev/null)

  local new_fonts=()
  while IFS= read -r font; do
    [[ -z "$font" ]] && continue
    if ! echo "$installed_casks" | grep -qx "$font"; then
      new_fonts+=("$font")
    fi
  done < <(grep '^cask "font-' "$BREWFILE" | sed 's/cask "\([^"]*\)".*/\1/' | sort)

  if [ ${#new_fonts[@]} -eq 0 ]; then
    return
  fi

  echo -e "\n${BLUE}=== Font Selection ===${NC}"
  echo -ne "${YELLOW}Install ${#new_fonts[@]} new font(s)?${NC} [Y/n]: "
  read -n 1 choice
  echo ""

  if [[ ! "$choice" =~ ^[Nn]$ ]]; then
    for font in "${new_fonts[@]}"; do
      echo "cask \"$font\"" >> "$TEMP_BREWFILE"
    done
    echo -e "${GREEN}✓${NC} Added ${#new_fonts[@]} font(s)"
  else
    echo -e "${YELLOW}Skipped fonts${NC}"
  fi
}

# Install everything
install_selected() {
  local has_new_casks=false
  if [ -f "$TEMP_BREWFILE" ] && [ -s "$TEMP_BREWFILE" ]; then
    has_new_casks=true
  fi

  # Check if formulae are already up to date
  local formulae_current=false
  if brew bundle check --file="$BREWFILE" --no-upgrade &>/dev/null; then
    formulae_current=true
  fi

  # Nothing to do
  if [ "$formulae_current" = true ] && [ "$has_new_casks" = false ]; then
    echo -e "\n${GREEN}✓ Everything already installed!${NC}"
    return 0
  fi

  # Build install list
  echo -e "\n${BLUE}=== Installation Summary ===${NC}"
  if [ "$formulae_current" = false ]; then
    echo -e "${BLUE}Formulae:${NC} new packages from Brewfile"
  fi
  if [ "$has_new_casks" = true ]; then
    echo -e "${BLUE}Casks:${NC}"
    grep '^cask ' "$TEMP_BREWFILE" | sed 's/cask "\([^"]*\)".*/  \1/'
  fi
  echo ""

  echo -ne "${YELLOW}Proceed?${NC} [Y/n]: "
  read -n 1 choice
  echo ""
  if [[ "$choice" =~ ^[Nn]$ ]]; then
    echo -e "${YELLOW}Installation cancelled${NC}"
    return 0
  fi

  # Merge formulae + selected casks into one Brewfile
  local merged="/tmp/brew_merged_$$"
  grep '^brew ' "$BREWFILE" > "$merged"
  if [ "$has_new_casks" = true ]; then
    cat "$TEMP_BREWFILE" >> "$merged"
  fi

  echo -e "\n${BLUE}Installing...${NC}"
  brew bundle install --file="$merged" --no-upgrade
  local exit_code=$?
  rm -f "$merged"

  if [ $exit_code -eq 0 ]; then
    echo -e "\n${GREEN}✓ Installation complete!${NC}"
  else
    echo -e "\n${RED}✗ Installation completed with errors${NC}"
  fi

  return $exit_code
}

cleanup() {
  rm -f "$TEMP_BREWFILE"
}

main() {
  echo -e "${BLUE}=== Brew Bundle Installer ===${NC}"

  check_homebrew

  if [ ! -f "$BREWFILE" ]; then
    echo -e "${RED}Error:${NC} Brewfile not found at $BREWFILE"
    exit 1
  fi

  trap cleanup EXIT
  rm -f "$TEMP_BREWFILE"

  select_applications
  select_fonts
  install_selected
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
