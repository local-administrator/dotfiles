# initialize Homebrew environment (Apple Silicon)
if test -x /opt/homebrew/bin/brew
    /opt/homebrew/bin/brew shellenv | source
end

# set defaults
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx PAGER less
set -gx MANPAGER "sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -lman'"
set -x LESSHISTFILE /dev/null

# work tools (only load if exists)
if test -f /path/to/work/tool.fish
    source /path/to/work/tool.fish
end

# add custom function path
set -p fish_function_path $HOME/.dotfiles/macos/fish/functions/custom

# source custom configs (if directory exists)
if test -d $HOME/.dotfiles/macos/fish/conf.d/custom
    for f in $HOME/.dotfiles/macos/fish/conf.d/custom/*.fish
        source $f
    end
end

# fzf (if installed)
if type -q fzf
    fzf --fish | source
end

# starship (if installed)
if type -q starship
    starship init fish | source
end

# source local/device-specific config (not tracked in git)
if test -f $HOME/.config/fish/config.local.fish
    source $HOME/.config/fish/config.local.fish
end
