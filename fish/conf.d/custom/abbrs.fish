# `rm` → `trash` abbreviation (moves files to the trash instead of deleting them)
# Requires `brew install trash`
if type -q trash
    abbr --add -g rm trash
end
