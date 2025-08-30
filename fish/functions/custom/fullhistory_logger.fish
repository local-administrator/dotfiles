function fullhistory_logger --on-event fish_postexec
    # Cache directory path in a universal variable to avoid repeated string concatenation
    if not set -q __fullhistory_log_dir
        set -U __fullhistory_log_dir "$HOME/.local/share/fish/fullhistory"
    end
    
    # Ensure directory exists (only check if not recently verified)
    if not set -q __fullhistory_dir_checked
        if not test -d "$__fullhistory_log_dir"
            mkdir -p "$__fullhistory_log_dir"
        end
        # Mark as checked for this session
        set -g __fullhistory_dir_checked 1
    end
    
    # Get the command that was just executed (from $argv[1]) and trim any trailing spaces
    set -l cmd (string trim -- "$argv[1]")
    
    # Get timestamp and month string in one date call
    set -l date_info (date '+%Y-%m-%d %H:%M:%S %Y-%m')
    set -l date_parts (string split ' ' -- $date_info)
    set -l timestamp "$date_parts[1] $date_parts[2]"
    set -l month_string $date_parts[3]
    
    # Log the command with timestamp to monthly file
    echo "$timestamp|$cmd" >> "$__fullhistory_log_dir/history_$month_string.log"
    
    # Clean up old logs (keep only last 4 months) - check occasionally
    if test (math (random) % 200) -eq 0
        # Find and remove log files older than 120 days
        find "$__fullhistory_log_dir" -name "history_*.log" -type f -mtime +120 -delete 2>/dev/null
    end
end