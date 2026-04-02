#!/bin/bash

# Interactive Brew Bundle Installer
# Shows only packages not already installed. Nothing installs without selection.

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

# Cache installed packages once
cache_installed() {
  INSTALLED_FORMULAE=$(brew list --formula 2>/dev/null)
  INSTALLED_CASKS=$(brew list --cask 2>/dev/null)
}

# Interactive picker using fzf, with Y/n fallback
# Writes selected items to TEMP_BREWFILE as brew/cask entries
# Usage: pick_and_add "brew" "Formulae" item1 item2 ...
pick_and_add() {
  local type="$1"
  local category="$2"
  shift 2
  local items=("$@")

  if [ ${#items[@]} -eq 0 ]; then
    echo -e "${GREEN}✓${NC} All $category already installed"
    return
  fi

  echo -e "\n${BLUE}=== ${#items[@]} new $category ===${NC}"

  local selected=""

  if command -v fzf &> /dev/null; then
    selected=$(printf '%s\n' "${items[@]}" | fzf \
      --multi \
      --bind 'ctrl-a:select-all' \
      --bind 'ctrl-d:deselect-all' \
      --header 'TAB: select | ctrl-a: all | ctrl-d: none | ESC: skip | ENTER: confirm' \
      --preview-window=hidden \
      --height=60% \
      --border) || true
  else
    # Fallback: list items and ask Y/n
    for item in "${items[@]}"; do
      echo "  $item"
    done
    echo ""
    echo -ne "${YELLOW}Install all ${#items[@]} $category?${NC} [Y/n]: "
    read -n 1 choice
    echo ""
    if [[ ! "$choice" =~ ^[Nn]$ ]]; then
      selected=$(printf '%s\n' "${items[@]}")
    fi
  fi

  if [ -n "$selected" ]; then
    while IFS= read -r item; do
      echo "${type} \"$item\"" >> "$TEMP_BREWFILE"
    done <<< "$selected"
    local count=$(echo "$selected" | wc -l | tr -d ' ')
    echo -e "${GREEN}Selected $count $category${NC}"
  else
    echo -e "${YELLOW}Skipped $category${NC}"
  fi
}

select_formulae() {
  local new_items=()
  while IFS= read -r formula; do
    [[ -z "$formula" ]] && continue
    if ! echo "$INSTALLED_FORMULAE" | grep -qx "$formula"; then
      new_items+=("$formula")
    fi
  done < <(grep '^brew ' "$BREWFILE" | sed 's/brew "\([^"]*\)".*/\1/' | sort)

  pick_and_add "brew" "formulae" "${new_items[@]}"
}

select_applications() {
  local new_items=()
  while IFS= read -r app; do
    [[ -z "$app" ]] && continue
    if ! echo "$INSTALLED_CASKS" | grep -qx "$app"; then
      new_items+=("$app")
    fi
  done < <(grep '^cask ' "$BREWFILE" | grep -v '^cask "font-' | sed 's/cask "\([^"]*\)".*/\1/' | sort)

  pick_and_add "cask" "applications" "${new_items[@]}"
}

select_fonts() {
  local new_items=()
  while IFS= read -r font; do
    [[ -z "$font" ]] && continue
    if ! echo "$INSTALLED_CASKS" | grep -qx "$font"; then
      new_items+=("$font")
    fi
  done < <(grep '^cask "font-' "$BREWFILE" | sed 's/cask "\([^"]*\)".*/\1/' | sort)

  pick_and_add "cask" "fonts" "${new_items[@]}"
}

install_selected() {
  if [ ! -f "$TEMP_BREWFILE" ] || [ ! -s "$TEMP_BREWFILE" ]; then
    echo -e "\n${YELLOW}Nothing selected to install${NC}"
    return 0
  fi

  echo -e "\n${BLUE}=== Installation Summary ===${NC}"
  local formulae casks
  formulae=$(grep '^brew ' "$TEMP_BREWFILE" | sed 's/brew "\([^"]*\)".*/  \1/')
  casks=$(grep '^cask ' "$TEMP_BREWFILE" | sed 's/cask "\([^"]*\)".*/  \1/')

  [ -n "$formulae" ] && echo -e "${BLUE}Formulae:${NC}" && echo "$formulae"
  [ -n "$casks" ] && echo -e "${BLUE}Casks:${NC}" && echo "$casks"
  echo ""

  echo -ne "${YELLOW}Proceed?${NC} [Y/n]: "
  read -n 1 choice
  echo ""
  if [[ "$choice" =~ ^[Nn]$ ]]; then
    echo -e "${YELLOW}Installation cancelled${NC}"
    return 0
  fi

  echo -e "\n${BLUE}Installing...${NC}"
  brew bundle install --file="$TEMP_BREWFILE" --no-upgrade
  local exit_code=$?

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
  cache_installed

  if [ ! -f "$BREWFILE" ]; then
    echo -e "${RED}Error:${NC} Brewfile not found at $BREWFILE"
    exit 1
  fi

  trap cleanup EXIT
  rm -f "$TEMP_BREWFILE"

  select_formulae
  select_applications
  select_fonts
  install_selected
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
