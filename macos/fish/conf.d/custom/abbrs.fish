# `rm` → `trash` abbreviation (moves files to the trash instead of deleting them)
# Requires `brew install trash`
if type -q trash
    abbr --add -g rm trash
end

# git shortcuts
abbr --add -g g git
abbr --add -g lg lazygit
