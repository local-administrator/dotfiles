# Abbreviations — expand visibly so the real command shows in history.
# Uses `abbr` instead of wrapper functions to avoid masking originals.
# Bypass any abbreviation with `command <original>` (e.g. `command cat`).

# Safe rm → trash
if type -q trash
    abbr --add -g rm trash
end

# bat as default cat (with pager disabled for pipe-friendliness)
if type -q bat
    abbr --add -g cat 'bat --pager=never'
end

# lsd as default ls
if type -q lsd
    abbr --add -g ls 'lsd --group-dirs first'
    abbr --add -g ll 'lsd -la --group-dirs first'
    abbr --add -g la 'lsd -a --group-dirs first'
end

# neovim as default vim
if type -q nvim
    abbr --add -g vim nvim
end

# git shortcuts
abbr --add -g g git
abbr --add -g lg lazygit
