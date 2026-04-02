#!/bin/bash

# Set default file associations using duti
# Requires: brew install duti

if ! command -v duti &> /dev/null; then
  echo "duti not found. Install with: brew install duti"
  exit 1
fi

EDITOR_ID="dev.zed.Zed"

# Text / Code
extensions=(
  txt md markdown
  json jsonc json5
  yml yaml toml xml csv log env
)

# Scripts / Programming
extensions+=(
  sh bash fish zsh ps1
  rb py js ts jsx tsx
  go rs c h cpp hpp
  lua java kt swift
  sql graphql
)

# Web (styles only — html/svg open in browser by default, which is correct)
extensions+=(
  css scss sass
)

# Config / Dotfiles
extensions+=(
  conf cfg ini
  gitignore gitconfig gitattributes
  editorconfig eslintrc prettierrc
  dockerfile
)

echo "Setting Zed as default editor for ${#extensions[@]} file types..."

for ext in "${extensions[@]}"; do
  duti -s "$EDITOR_ID" ".$ext" all 2>/dev/null
done

echo "Done."
