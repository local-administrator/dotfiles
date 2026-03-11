function fullhistory -d "Show command history with detailed timestamps"
    # Use cached directory path
    if not set -q __fullhistory_log_dir
        set -U __fullhistory_log_dir "$HOME/.local/share/fish/fullhistory"
    end
    set -l history_log_dir "$__fullhistory_log_dir"
    
    # Set color variables
    set -l date_color (set_color blue)
    set -l time_pacific_color (set_color green) 
    set -l time_utc_color (set_color yellow)
    set -l cmd_color (set_color normal)
    set -l separator_color (set_color brblack)
    set -l number_color (set_color magenta)
    set -l reset (set_color normal)
    
    # Parse arguments
    set -l limit 50
    set -l export_mode ""
    
    for arg in $argv
        switch $arg
            case '--export' '-e'
                set export_mode "simple"
            case '--export-detailed' '-ed'
                set export_mode "detailed"
            case '*'
                if string match -qr '^\d+$' -- $arg
                    set limit $arg
                end
        end
    end
    
    # Get entries based on export mode or display limit
    set -l entries
    
    if test "$export_mode" != ""
        # For exports, get last 7 days of data
        set -l seven_days_ago (date -v-7d '+%Y-%m-%d' 2>/dev/null || date -d '7 days ago' '+%Y-%m-%d')
        
        # Check current and previous month's logs (in case we're early in the month)
        set -l current_month (date '+%Y-%m')
        set -l last_month (date -v-1m '+%Y-%m' 2>/dev/null || date -d '1 month ago' '+%Y-%m')
        
        set entries
        for month in $current_month $last_month
            set -l log_file "$history_log_dir/history_$month.log"
            if test -f "$log_file"
                # Filter entries from last 7 days
                while read -l line
                    # Skip comment lines
                    if string match -q "#*" -- "$line"
                        continue
                    end
                    
                    set -l entry_date (string split '|' -- $line)[1]
                    if test -n "$entry_date"
                        set -l date_part (string split ' ' -- $entry_date)[1]
                        # Compare dates as numbers by removing hyphens (YYYYMMDD format)
                        set -l date_num (string replace -a '-' '' -- "$date_part")
                        set -l cutoff_num (string replace -a '-' '' -- "$seven_days_ago")
                        if test -n "$date_num" -a -n "$cutoff_num"
                            # Make sure they're valid numbers before comparing
                            if string match -qr '^\d+$' -- "$date_num" "$cutoff_num"
                                if test "$date_num" -ge "$cutoff_num"
                                    set entries $entries $line
                                end
                            end
                        end
                    end
                end < "$log_file"
            end
        end
        
        if test (count $entries) -eq 0
            echo "No history found for the last 7 days"
            return
        end
    else
        # For regular display, get recent entries efficiently from monthly logs
        set -l all_logs (ls -1t "$history_log_dir"/history_*.log 2>/dev/null | head -2) # Only check last 2 months
        
        if test (count $all_logs) -eq 0
            echo "No history log files found. Commands will be logged as you run them."
            echo "Logs are stored in: $history_log_dir"
            return
        end
        
        # Get the most recent N entries
        if test (count $all_logs) -eq 1
            # Single file, just tail it
            set entries (tail -n $limit $all_logs 2>/dev/null)
        else
            # Multiple files, get from most recent first
            set entries
            set -l remaining $limit
            for log in $all_logs
                if test $remaining -le 0
                    break
                end
                set -l log_entries (tail -n $remaining "$log" 2>/dev/null)
                set entries $log_entries $entries
                set remaining (math $remaining - (count $log_entries))
            end
            # Ensure we have exactly $limit entries
            set entries (printf '%s\n' $entries | tail -n $limit)
        end
    end
    
    if test "$export_mode" = "simple"
        # Simple markdown export - one line per command
        echo "# Command History Export"
        echo ""
        echo "Generated: "(date '+%Y-%m-%d %H:%M:%S %Z')
        echo ""
        
        for entry in $entries
            if string match -qr '^([^|]+)\|(.*)' -- "$entry"
                set -l matches (string match -r '^([^|]+)\|(.*)' -- "$entry")
                if test (count $matches) -ge 3
                    set -l timestamp $matches[2]
                    set -l cmd $matches[3]
                    
                    set -l unix_ts (date -j -f "%Y-%m-%d %H:%M:%S" "$timestamp" "+%s" 2>/dev/null)
                    if test -n "$unix_ts"
                        set -l utc_time (TZ='UTC' date -r $unix_ts '+%Y-%m-%d %H:%M:%S UTC')
                        echo "**$utc_time**: `$cmd`"
                    end
                end
            end
        end
        
    else if test "$export_mode" = "detailed"
        # Detailed markdown export - grouped by day
        echo "# Command History Export (Detailed)"
        echo ""
        echo "Generated: "(date '+%Y-%m-%d %H:%M:%S %Z')
        echo ""
        
        set -l current_date ""
        set -l day_commands
        
        for entry in $entries
            if string match -qr '^([^|]+)\|(.*)' -- "$entry"
                set -l matches (string match -r '^([^|]+)\|(.*)' -- "$entry")
                if test (count $matches) -ge 3
                    set -l timestamp $matches[2]
                    set -l cmd $matches[3]
                    
                    set -l date_part (string split ' ' -- $timestamp)[1]
                    
                    set -l unix_ts (date -j -f "%Y-%m-%d %H:%M:%S" "$timestamp" "+%s" 2>/dev/null)
                    if test -n "$unix_ts"
                        set -l utc_date (TZ='UTC' date -r $unix_ts '+%Y-%m-%d')
                        set -l utc_time (TZ='UTC' date -r $unix_ts '+%H:%M:%S')
                        
                        # Start new day block if date changed
                        if test "$utc_date" != "$current_date"
                            # Output previous day's commands if any
                            if test -n "$current_date" -a (count $day_commands) -gt 0
                                echo '```bash'
                                for cmd_line in $day_commands
                                    echo $cmd_line
                                end
                                echo '```'
                                echo ""
                            end
                            
                            # Start new day
                            set current_date $utc_date
                            set day_commands
                            echo "**$utc_date**"
                        end
                        
                        # Add command to current day
                        set day_commands $day_commands "$utc_time UTC: $cmd"
                    end
                end
            end
        end
        
        # Output last day's commands
        if test (count $day_commands) -gt 0
            echo '```bash'
            for cmd_line in $day_commands
                echo $cmd_line
            end
            echo '```'
        end
        
    else
        # Pretty display mode
        echo "📜 Showing last $limit commands with timestamps:"
        echo ""
        
        set -l counter 1
        
        for entry in $entries
            # Parse our log format: timestamp|command
            if string match -qr '^([^|]+)\|(.*)' -- "$entry"
                set -l matches (string match -r '^([^|]+)\|(.*)' -- "$entry")
                
                if test (count $matches) -ge 3
                    set -l timestamp $matches[2]
                    set -l cmd $matches[3]
                    
                    # Parse date and time parts efficiently
                    set -l date_part (string split ' ' -- $timestamp)[1]
                    set -l time_part (string split ' ' -- $timestamp)[2]
                    
                    # Convert to timezone strings
                    set -l unix_ts (date -j -f "%Y-%m-%d %H:%M:%S" "$timestamp" "+%s" 2>/dev/null)
                    
                    if test -n "$unix_ts"
                        # Get Pacific and UTC times
                        set -l pacific_time (TZ='America/Los_Angeles' date -r $unix_ts '+%H:%M:%S PST')
                        set -l utc_time (TZ='UTC' date -r $unix_ts '+%H:%M:%S UTC')
                        
                        # Pretty output
                        echo -n "$number_color#$counter$reset "
                        echo -n "$date_color$date_part$reset "
                        echo -n "$separator_color│$reset "
                        echo -n "$time_pacific_color$pacific_time$reset "
                        echo -n "$separator_color│$reset "
                        echo -n "$time_utc_color$utc_time$reset"
                        echo ""
                        echo "  $separator_color→$reset $cmd_color$cmd$reset"
                        echo ""
                    else
                        # Fallback if date conversion fails
                        echo -n "$number_color#$counter$reset "
                        echo -n "$date_color$date_part$reset "
                        echo -n "$separator_color│$reset "
                        echo -n "$time_pacific_color$time_part$reset"
                        echo ""
                        echo "  $separator_color→$reset $cmd_color$cmd$reset"
                        echo ""
                    end
                end
            end
            
            set counter (math $counter + 1)
        end
    end
end