# Logs are stored in monthly files in ~/.local/share/fish/fullhistory/

if test -f $HOME/.dotfiles/macos/fish/functions/custom/fullhistory_logger.fish
    source $HOME/.dotfiles/macos/fish/functions/custom/fullhistory_logger.fish
end

# Set up directory structure for monthly logs
set -l history_log_dir "$HOME/.local/share/fish/fullhistory"

if not test -d "$history_log_dir"
    mkdir -p "$history_log_dir"
end

# Create initial month log if it doesn't exist
set -l current_month (date '+%Y-%m')
set -l month_log "$history_log_dir/history_$current_month.log"

if not test -f "$month_log"
    echo "# Full history log for month $current_month initialized at "(date '+%Y-%m-%d %H:%M:%S') > "$month_log"
end
