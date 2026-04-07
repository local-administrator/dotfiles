function gitgrabber -d "Mirror a GitHub organization locally — clone new repos, pull updates"
    argparse 'h/help' 'n/dry-run' 'f/include-forks' 'a/include-archived' \
        'j/jobs=' 'p/protocol=' 'q/quiet' 'i/interactive' 'y/yes' -- $argv
    or return

    # ── Colors ────────────────────────────────────────────────────────
    set -l bold (set_color --bold)
    set -l dim (set_color brblack)
    set -l green (set_color green)
    set -l yellow (set_color yellow)
    set -l red (set_color red)
    set -l cyan (set_color cyan)
    set -l reset (set_color normal)

    # ── Help ──────────────────────────────────────────────────────────
    if set -q _flag_help
        echo ""
        echo "  $bold""gitgrabber$reset — mirror a GitHub organization locally"
        echo ""
        echo "  $bold""USAGE$reset"
        echo "    gitgrabber <org> [options]"
        echo ""
        echo "  $bold""DESCRIPTION$reset"
        echo "    Clones new repos and pulls updates for all repos in a GitHub"
        echo "    organization. Repos are stored in ~/src/github.com/<org>/."
        echo ""
        echo "    Forks, archived, and empty repos are skipped by default."
        echo "    Repos with uncommitted changes are never touched."
        echo ""
        echo "  $bold""MODES$reset"
        echo "    $dim""(default)$reset                  Preview changes, prompt to confirm"
        echo "    "$green"-i$reset, $green""--interactive$reset         Pick repos with fzf multi-select"
        echo "    "$green"-y$reset, $green""--yes$reset                 Skip confirmation, run everything"
        echo ""
        echo "  $bold""OPTIONS$reset"
        echo "    "$green"-n$reset, $green""--dry-run$reset              Preview actions without making changes"
        echo "    "$green"-f$reset, $green""--include-forks$reset        Include forked repos"
        echo "    "$green"-a$reset, $green""--include-archived$reset     Include archived repos"
        echo "    "$green"-j$reset, $green""--jobs$reset $dim""N$reset                 Max parallel jobs $dim""(default: 4)$reset"
        echo "    "$green"-p$reset, $green""--protocol$reset $dim""PROTO$reset         Clone protocol: https or ssh $dim""(default: https)$reset"
        echo "    "$green"-q$reset, $green""--quiet$reset                Only show changes and summary"
        echo "    "$green"-h$reset, $green""--help$reset                 Show this help"
        echo ""
        echo "  $bold""EXAMPLES$reset"
        echo "    $dim""# Sync an org (preview + confirm)$reset"
        echo "    gitgrabber my-org"
        echo ""
        echo "    $dim""# Pick which repos to sync$reset"
        echo "    gitgrabber my-org -i"
        echo ""
        echo "    $dim""# No prompts (for scripting/cron)$reset"
        echo "    gitgrabber my-org -y"
        echo ""
        echo "    $dim""# Include everything, clone via SSH$reset"
        echo "    gitgrabber my-org -f -a --protocol ssh"
        echo ""
        echo "  $bold""REQUIRES$reset"
        echo "    gh $dim""(GitHub CLI, authenticated via gh auth login)$reset"
        echo "    git, python3"
        echo "    fzf $dim""(only for --interactive mode)$reset"
        echo ""
        return 0
    end

    # ── Validate args ─────────────────────────────────────────────────
    if test (count $argv) -ne 1
        echo "$red""gitgrabber:$reset expected exactly one argument: <org>" >&2
        echo "Run '$cyan""gitgrabber --help$reset' for usage." >&2
        return 1
    end

    set -l org $argv[1]
    set -l base_dir "$HOME/src/github.com/$org"
    set -l max_jobs (test -n "$_flag_jobs" && echo "$_flag_jobs" || echo 4)
    set -l protocol (test -n "$_flag_protocol" && echo "$_flag_protocol" || echo https)
    set -l dry_run (set -q _flag_dry_run && echo 1 || echo 0)
    set -l quiet (set -q _flag_quiet && echo 1 || echo 0)
    set -l interactive (set -q _flag_interactive && echo 1 || echo 0)
    set -l auto_yes (set -q _flag_yes && echo 1 || echo 0)
    set -l start_time (date +%s)

    if not string match -qr '^(https|ssh)$' -- $protocol
        echo "$red""gitgrabber:$reset invalid protocol '$protocol'. Use 'https' or 'ssh'." >&2
        return 1
    end

    if not string match -qr '^[0-9]+$' -- $max_jobs; or test $max_jobs -lt 1
        echo "$red""gitgrabber:$reset --jobs must be a positive integer." >&2
        return 1
    end

    if test $interactive -eq 1; and not command -q fzf
        echo "$red""gitgrabber:$reset --interactive requires 'fzf' but it's not installed." >&2
        return 1
    end

    # ── Pre-flight checks ────────────────────────────────────────────
    if not command -q gh
        echo "$red""gitgrabber:$reset 'gh' (GitHub CLI) is required but not installed." >&2
        echo "  Install it → $cyan""https://cli.github.com/$reset" >&2
        return 1
    end

    if not command -q git
        echo "$red""gitgrabber:$reset 'git' is required but not installed." >&2
        return 1
    end

    if not gh auth status &>/dev/null
        echo "$red""gitgrabber:$reset GitHub CLI is not authenticated." >&2
        echo "  Run '$cyan""gh auth login$reset' to authenticate, then try again." >&2
        return 1
    end

    # ── Fetch repo list ──────────────────────────────────────────────
    set -l fields "name,defaultBranchRef,isArchived,isFork,isEmpty,url,sshUrl"
    set -l repo_json (gh repo list $org --json $fields --limit 1000 2>&1)
    if test $status -ne 0
        echo "$red""gitgrabber:$reset failed to list repos for '$org':" >&2
        echo "  $repo_json" >&2
        return 1
    end

    # Parse repo list JSON into pipe-delimited lines:
    #   name|default_branch|is_archived|is_fork|is_empty|https_url|ssh_url
    set -l repo_lines (echo $repo_json | python3 -c "
import sys, json
repos = json.load(sys.stdin)
for r in repos:
    branch = r.get('defaultBranchRef') or {}
    branch_name = branch.get('name', 'main') if branch else 'main'
    print('|'.join([
        r['name'],
        branch_name,
        str(r.get('isArchived', False)),
        str(r.get('isFork', False)),
        str(r.get('isEmpty', False)),
        r.get('url', ''),
        r.get('sshUrl', ''),
    ]))
" 2>&1)

    if test $status -ne 0
        echo "$red""gitgrabber:$reset failed to parse repo list:" >&2
        echo "  $repo_lines" >&2
        return 1
    end

    if test (count $repo_lines) -eq 0
        echo "$yellow""gitgrabber:$reset no repos found for '$org'."
        return 0
    end

    # ── Filter repos ─────────────────────────────────────────────────
    set -l filtered_repos
    set -l skipped_archived 0
    set -l skipped_forks 0
    set -l skipped_empty 0

    for line in $repo_lines
        set -l parts (string split '|' -- $line)
        if test (count $parts) -lt 7
            continue
        end

        set -l r_name $parts[1]
        set -l r_archived $parts[3]
        set -l r_fork $parts[4]
        set -l r_empty $parts[5]
        set -l r_https $parts[6]
        set -l r_ssh $parts[7]

        if test "$r_empty" = True
            set skipped_empty (math $skipped_empty + 1)
            continue
        end

        if test "$r_archived" = True; and not set -q _flag_include_archived
            set skipped_archived (math $skipped_archived + 1)
            continue
        end

        if test "$r_fork" = True; and not set -q _flag_include_forks
            set skipped_forks (math $skipped_forks + 1)
            continue
        end

        set -l clone_url
        if test "$protocol" = ssh
            set clone_url $r_ssh
        else
            set clone_url "$r_https"
        end

        # Store: name|branch|archived|clone_url
        set -a filtered_repos "$parts[1]|$parts[2]|$r_archived|$clone_url"
    end

    # ── Determine local state ────────────────────────────────────────
    mkdir -p $base_dir

    set -l local_dirs
    if test -d $base_dir
        for d in $base_dir/*/
            set -a local_dirs (basename $d)
        end
    end

    set -l remote_names
    for entry in $filtered_repos
        set -l parts (string split '|' -- $entry)
        set -a remote_names $parts[1]
    end

    # ── Header ───────────────────────────────────────────────────────
    set -l total_remote (count $repo_lines)
    set -l total_filtered (count $filtered_repos)

    echo ""
    echo "  $bold""gitgrabber$reset  $dim""·$reset  $org → $dim$base_dir/$reset"
    echo "  $dim""$total_remote repos in org, $total_filtered after filters$reset"

    if test $skipped_forks -gt 0
        echo "  $dim""$skipped_forks forks skipped (use --include-forks)$reset"
    end
    if test $skipped_archived -gt 0
        echo "  $dim""$skipped_archived archived skipped (use --include-archived)$reset"
    end
    if test $skipped_empty -gt 0
        echo "  $dim""$skipped_empty empty repos skipped$reset"
    end
    echo ""

    # ══════════════════════════════════════════════════════════════════
    # PHASE 1: Categorize — parallel fetch + compare
    # ══════════════════════════════════════════════════════════════════
    echo "  $dim""Checking repos...$reset"

    set -l tmp_dir (mktemp -d)
    set -l active_jobs 0

    for entry in $filtered_repos
        while test $active_jobs -ge $max_jobs
            wait -n 2>/dev/null
            set active_jobs (jobs -p | count)
        end

        fish --no-config -c "
            set -l entry '$entry'
            set -l base_dir '$base_dir'
            set -l tmp_dir '$tmp_dir'
            set -l protocol '$protocol'

            set -l parts (string split '|' -- \$entry)
            set -l r_name \$parts[1]
            set -l r_branch \$parts[2]
            set -l r_archived \$parts[3]
            set -l clone_url \$parts[4]
            set -l repo_dir \"\$base_dir/\$r_name\"
            set -l cat_file \"\$tmp_dir/\$r_name\"

            set -l archived_tag ''
            if test \"\$r_archived\" = True
                set archived_tag ' [archived]'
            end

            # ── Not cloned yet ───────────────────────────────────
            if not test -d \"\$repo_dir\"
                echo \"STATUS:clone\" > \$cat_file
                echo \"BRANCH:\$r_branch\" >> \$cat_file
                echo \"URL:\$clone_url\" >> \$cat_file
                echo \"TAG:\$archived_tag\" >> \$cat_file
                return
            end

            # ── Not a git repo ───────────────────────────────────
            if not test -d \"\$repo_dir/.git\"
                echo \"STATUS:skip\" > \$cat_file
                echo \"REASON:not a git repo\" >> \$cat_file
                echo \"TAG:\$archived_tag\" >> \$cat_file
                return
            end

            # ── Fix stale remote URL ─────────────────────────────
            set -l current_remote (git -C \$repo_dir remote get-url origin 2>/dev/null)
            if test -n \"\$current_remote\"; and test \"\$current_remote\" != \"\$clone_url\"
                git -C \$repo_dir remote set-url origin \$clone_url 2>/dev/null
            end

            # ── Dirty working tree ───────────────────────────────
            set -l dirty (git -C \$repo_dir status --porcelain 2>/dev/null)
            if test -n \"\$dirty\"
                echo \"STATUS:dirty\" > \$cat_file
                echo \"TAG:\$archived_tag\" >> \$cat_file
                return
            end

            # ── Fetch from remote ────────────────────────────────
            if not git -C \$repo_dir fetch --all --prune --quiet 2>&1
                echo \"STATUS:error\" > \$cat_file
                echo \"REASON:fetch failed\" >> \$cat_file
                echo \"TAG:\$archived_tag\" >> \$cat_file
                return
            end

            # ── Check remote branch exists ───────────────────────
            if not git -C \$repo_dir rev-parse --verify origin/\$r_branch &>/dev/null
                echo \"STATUS:skip\" > \$cat_file
                echo \"REASON:remote branch 'origin/\$r_branch' not found\" >> \$cat_file
                echo \"TAG:\$archived_tag\" >> \$cat_file
                return
            end

            # ── Compare local vs remote ──────────────────────────
            # Get the local default branch HEAD (or current HEAD if not on default)
            set -l local_head
            if git -C \$repo_dir rev-parse --verify \$r_branch &>/dev/null
                set local_head (git -C \$repo_dir rev-parse \$r_branch 2>/dev/null)
            else
                # Default branch doesn't exist locally yet — treat as needing pull
                echo \"STATUS:pull\" > \$cat_file
                echo \"BRANCH:\$r_branch\" >> \$cat_file
                echo \"URL:\$clone_url\" >> \$cat_file
                echo \"COMMITS:?\" >> \$cat_file
                echo \"TAG:\$archived_tag\" >> \$cat_file
                return
            end

            set -l remote_head (git -C \$repo_dir rev-parse origin/\$r_branch 2>/dev/null)

            if test \"\$local_head\" = \"\$remote_head\"
                echo \"STATUS:current\" > \$cat_file
                echo \"TAG:\$archived_tag\" >> \$cat_file
                return
            end

            # ── Has new commits ──────────────────────────────────
            set -l commit_count (git -C \$repo_dir rev-list --count \$local_head..\$remote_head 2>/dev/null)
            set -l log_lines (git -C \$repo_dir log --oneline \$local_head..\$remote_head 2>/dev/null | head -5)

            echo \"STATUS:pull\" > \$cat_file
            echo \"BRANCH:\$r_branch\" >> \$cat_file
            echo \"URL:\$clone_url\" >> \$cat_file
            echo \"COMMITS:\$commit_count\" >> \$cat_file
            for log_line in \$log_lines
                echo \"LOG:\$log_line\" >> \$cat_file
            end
            if test \$commit_count -gt 5
                echo \"MORE:\"(math \$commit_count - 5) >> \$cat_file
            end
            echo \"TAG:\$archived_tag\" >> \$cat_file
        " &

        set active_jobs (jobs -p | count)
    end

    wait

    # ── Read categorization results ──────────────────────────────────
    set -l repos_clone     # repos that need cloning
    set -l repos_pull      # repos that need pulling
    set -l repos_current   # repos up to date
    set -l repos_dirty     # repos with dirty working trees
    set -l repos_skip      # repos skipped for other reasons
    set -l repos_error     # repos with errors

    for cat_file in (find $tmp_dir -type f | sort)
        set -l r_name (basename $cat_file)
        set -l status_line (grep '^STATUS:' $cat_file | head -1)
        set -l status_val (string replace 'STATUS:' '' -- $status_line)

        switch $status_val
            case clone
                set -a repos_clone $r_name
            case pull
                set -a repos_pull $r_name
            case current
                set -a repos_current $r_name
            case dirty
                set -a repos_dirty $r_name
            case skip
                set -a repos_skip $r_name
            case error
                set -a repos_error $r_name
        end
    end

    # Detect orphans
    set -l repos_orphan
    for local_name in $local_dirs
        if not contains -- $local_name $remote_names
            set -a repos_orphan $local_name
        end
    end

    # Clear the "Checking repos..." line
    printf "\r\033[K"

    # ══════════════════════════════════════════════════════════════════
    # PHASE 2: Present — show what we found
    # ══════════════════════════════════════════════════════════════════

    # Helper: print repo detail for a pull repo
    function _gg_print_pull_detail -a r_name tmp_dir dim reset
        set -l cat_file "$tmp_dir/$r_name"
        set -l commits (grep '^COMMITS:' $cat_file | string replace 'COMMITS:' '')
        set -l commit_str
        if test "$commits" = "?"
            set commit_str "new commits available"
        else
            set commit_str "$commits new commit(s)"
        end
        echo "  🔄 $r_name — $commit_str"
        for log_line in (grep '^LOG:' $cat_file | string replace 'LOG:' '')
            echo "  $dim   · $log_line$reset"
        end
        set -l more (grep '^MORE:' $cat_file | string replace 'MORE:' '')
        if test -n "$more"
            echo "  $dim   … and $more more$reset"
        end
    end

    # Determine what actions are available
    set -l actionable_count (math (count $repos_clone) + (count $repos_pull))

    if test $actionable_count -eq 0
        # Nothing to do — just show status
        echo "  $green""Everything up to date$reset — $dim"(count $repos_current)" repos current$reset"

        if test (count $repos_dirty) -gt 0
            echo ""
            for r in $repos_dirty
                echo "  ⚠️  $r — $yellow""dirty working tree$reset"
            end
        end
        if test (count $repos_orphan) -gt 0
            echo ""
            for r in $repos_orphan
                echo "  👻 $r — $dim""orphaned (not in org)$reset"
            end
        end
        if test (count $repos_error) -gt 0
            echo ""
            for r in $repos_error
                set -l reason (grep '^REASON:' "$tmp_dir/$r" | string replace 'REASON:' '')
                echo "  ❌ $r — $red""$reason$reset"
            end
        end

        set -l end_time (date +%s)
        echo ""
        echo "  $dim""Completed in "(math $end_time - $start_time)"s$reset"
        echo ""
        rm -rf $tmp_dir
        functions -e _gg_print_pull_detail
        return 0
    end

    # ── Show preview ─────────────────────────────────────────────────
    if test (count $repos_clone) -gt 0
        echo "  $bold""To clone$reset $dim""("(count $repos_clone)")$reset"
        for r in $repos_clone
            set -l tag (grep '^TAG:' "$tmp_dir/$r" | string replace 'TAG:' '')
            echo "  📥 $r$tag"
        end
        echo ""
    end

    if test (count $repos_pull) -gt 0
        echo "  $bold""To update$reset $dim""("(count $repos_pull)")$reset"
        for r in $repos_pull
            _gg_print_pull_detail $r $tmp_dir $dim $reset
        end
        echo ""
    end

    if test $quiet -eq 0
        if test (count $repos_current) -gt 0
            echo "  $dim""Up to date ("(count $repos_current)"): "(string join ", " -- $repos_current)"$reset"
            echo ""
        end
    end

    if test (count $repos_dirty) -gt 0
        for r in $repos_dirty
            echo "  ⚠️  $r — $yellow""dirty working tree$reset"
        end
        echo ""
    end

    if test (count $repos_error) -gt 0
        for r in $repos_error
            set -l reason (grep '^REASON:' "$tmp_dir/$r" | string replace 'REASON:' '')
            echo "  ❌ $r — $red""$reason$reset"
        end
        echo ""
    end

    if test (count $repos_orphan) -gt 0
        for r in $repos_orphan
            echo "  👻 $r — $dim""orphaned (not in org)$reset"
        end
        echo ""
    end

    # ── Dry run stops here ───────────────────────────────────────────
    if test $dry_run -eq 1
        echo "  $yellow""DRY RUN$reset — no changes made"
        set -l end_time (date +%s)
        echo "  $dim""Completed in "(math $end_time - $start_time)"s$reset"
        echo ""
        rm -rf $tmp_dir
        functions -e _gg_print_pull_detail
        return 0
    end

    # ══════════════════════════════════════════════════════════════════
    # PHASE 2b: Select — choose which repos to act on
    # ══════════════════════════════════════════════════════════════════

    set -l selected_repos

    if test $interactive -eq 1
        # ── fzf multi-select picker ──────────────────────────────
        set -l fzf_lines
        for r in $repos_clone
            set -l tag (grep '^TAG:' "$tmp_dir/$r" | string replace 'TAG:' '' | string trim)
            set -a fzf_lines "📥 clone   $r$tag"
        end
        for r in $repos_pull
            set -l commits (grep '^COMMITS:' "$tmp_dir/$r" | string replace 'COMMITS:' '')
            set -l tag (grep '^TAG:' "$tmp_dir/$r" | string replace 'TAG:' '' | string trim)
            if test "$commits" = "?"
                set -a fzf_lines "🔄 pull    $r  (new commits)$tag"
            else
                set -a fzf_lines "🔄 pull    $r  ($commits new)$tag"
            end
        end
        # Include current repos as deselected options
        for r in $repos_current
            set -a fzf_lines "✅ current $r"
        end

        # Build pre-select pattern: select clone and pull lines
        set -l selected_lines (printf '%s\n' $fzf_lines | \
            fzf --multi \
                --ansi \
                --header="Tab: toggle · Enter: confirm · Esc: cancel" \
                --prompt="  gitgrabber > " \
                --bind "ctrl-a:select-all,ctrl-d:deselect-all" \
                --preview-window=hidden \
                --no-sort \
                --select-1 \
            2>/dev/null)

        if test $status -ne 0; or test -z "$selected_lines"
            echo "  $dim""Cancelled.$reset"
            echo ""
            rm -rf $tmp_dir
            functions -e _gg_print_pull_detail
            return 0
        end

        # Parse repo names from selected fzf lines
        for line in $selected_lines
            # Format: "📥 clone   repo-name" or "🔄 pull    repo-name  (N new)"
            # Extract the repo name (3rd whitespace-separated field, strip trailing info)
            set -l repo_name (echo $line | string replace -r '^\S+\s+\S+\s+' '' | string replace -r '\s+\(.*' '' | string trim)
            set -a selected_repos $repo_name
        end

    else if test $auto_yes -eq 1
        # ── Auto mode: select all actionable repos ───────────────
        for r in $repos_clone $repos_pull
            set -a selected_repos $r
        end

    else
        # ── Default: preview + confirm ───────────────────────────
        printf "  Proceed? [Y/n] "
        read -l confirm
        switch (string lower -- $confirm)
            case '' y yes
                for r in $repos_clone $repos_pull
                    set -a selected_repos $r
                end
            case '*'
                echo "  $dim""Cancelled.$reset"
                echo ""
                rm -rf $tmp_dir
                functions -e _gg_print_pull_detail
                return 0
        end
    end

    if test (count $selected_repos) -eq 0
        echo "  $dim""Nothing selected.$reset"
        echo ""
        rm -rf $tmp_dir
        functions -e _gg_print_pull_detail
        return 0
    end

    echo ""

    # ══════════════════════════════════════════════════════════════════
    # PHASE 3: Execute — clone and pull selected repos
    # ══════════════════════════════════════════════════════════════════

    set -l exec_dir (mktemp -d)
    set active_jobs 0

    for r_name in $selected_repos
        while test $active_jobs -ge $max_jobs
            wait -n 2>/dev/null
            set active_jobs (jobs -p | count)
        end

        fish --no-config -c "
            set -l r_name '$r_name'
            set -l base_dir '$base_dir'
            set -l tmp_dir '$tmp_dir'
            set -l exec_dir '$exec_dir'

            set -l cat_file \"\$tmp_dir/\$r_name\"
            set -l result_file \"\$exec_dir/\$r_name\"
            set -l repo_dir \"\$base_dir/\$r_name\"

            set -l status_val (grep '^STATUS:' \$cat_file | head -1 | string replace 'STATUS:' '')
            set -l r_branch (grep '^BRANCH:' \$cat_file | head -1 | string replace 'BRANCH:' '')
            set -l clone_url (grep '^URL:' \$cat_file | head -1 | string replace 'URL:' '')
            set -l tag (grep '^TAG:' \$cat_file | string replace 'TAG:' '' | string trim)

            if test \"\$status_val\" = clone
                if git clone --quiet \$clone_url \$repo_dir 2>&1
                    echo \"📥 \$r_name — cloned\$tag\" > \$result_file
                    echo 'ACTION:clone' >> \$result_file
                else
                    echo \"❌ \$r_name — clone failed\" > \$result_file
                    echo 'ACTION:error' >> \$result_file
                end
                return
            end

            if test \"\$status_val\" = pull; or test \"\$status_val\" = current
                # Switch to default branch if needed
                set -l current_branch (git -C \$repo_dir branch --show-current 2>/dev/null)
                if test \"\$current_branch\" != \"\$r_branch\"
                    if not git -C \$repo_dir switch \$r_branch --quiet 2>&1
                        if not git -C \$repo_dir switch --create \$r_branch --track origin/\$r_branch --quiet 2>&1
                            echo \"❌ \$r_name — failed to switch to \$r_branch\" > \$result_file
                            echo 'ACTION:error' >> \$result_file
                            return
                        end
                    end
                end

                set -l old_head (git -C \$repo_dir rev-parse HEAD 2>/dev/null)

                if not git -C \$repo_dir pull --ff-only --quiet 2>&1
                    echo \"⚠️  \$r_name — pull failed (diverged?)\" > \$result_file
                    echo 'ACTION:skip' >> \$result_file
                    return
                end

                set -l new_head (git -C \$repo_dir rev-parse HEAD 2>/dev/null)

                if test \"\$old_head\" = \"\$new_head\"
                    echo \"✅ \$r_name — up to date\$tag\" > \$result_file
                    echo 'ACTION:current' >> \$result_file
                else
                    set -l commit_count (git -C \$repo_dir rev-list --count \$old_head..\$new_head 2>/dev/null)
                    set -l log_lines (git -C \$repo_dir log --oneline \$old_head..\$new_head 2>/dev/null | head -5)
                    set -l more ''
                    if test \$commit_count -gt 5
                        set more \"   … and \"(math \$commit_count - 5)\" more\"
                    end

                    echo \"🔄 \$r_name — \$commit_count new commit(s)\$tag\" > \$result_file
                    for log_line in \$log_lines
                        echo \"   · \$log_line\" >> \$result_file
                    end
                    if test -n \"\$more\"
                        echo \"\$more\" >> \$result_file
                    end
                    echo 'ACTION:update' >> \$result_file
                end
            end
        " &

        set active_jobs (jobs -p | count)
    end

    wait

    # ── Collect execution results ────────────────────────────────────
    set -l count_cloned 0
    set -l count_updated 0
    set -l count_current 0
    set -l count_skipped (count $repos_dirty)
    set -l count_errors (count $repos_error)

    for result_file in (find $exec_dir -type f | sort)
        set -l lines (cat $result_file)
        set -l action_line $lines[-1]
        set -l action (string replace 'ACTION:' '' -- $action_line)

        switch $action
            case clone
                set count_cloned (math $count_cloned + 1)
            case update
                set count_updated (math $count_updated + 1)
            case current
                set count_current (math $count_current + 1)
            case skip
                set count_skipped (math $count_skipped + 1)
            case error
                set count_errors (math $count_errors + 1)
        end

        if test $quiet -eq 0
            for line in $lines[1..-2]
                echo "  $line"
            end
        else
            if test "$action" != current
                for line in $lines[1..-2]
                    echo "  $line"
                end
            end
        end
    end

    # Add repos that weren't selected to current count
    set -l not_selected (math $total_filtered - (count $selected_repos) - (count $repos_dirty) - (count $repos_error) - (count $repos_skip))
    if test $not_selected -gt 0
        set count_current (math $count_current + $not_selected)
    end

    # ── Summary ──────────────────────────────────────────────────────
    set -l end_time (date +%s)
    set -l elapsed (math $end_time - $start_time)

    echo ""
    echo "  $bold""Summary$reset"

    set -l summary_parts
    if test $count_cloned -gt 0
        set -a summary_parts "$green$count_cloned cloned$reset"
    end
    if test $count_updated -gt 0
        set -a summary_parts "$cyan$count_updated updated$reset"
    end
    if test $count_current -gt 0
        set -a summary_parts "$dim$count_current current$reset"
    end
    if test $count_skipped -gt 0
        set -a summary_parts "$yellow$count_skipped skipped$reset"
    end
    if test $count_errors -gt 0
        set -a summary_parts "$red$count_errors errors$reset"
    end
    if test (count $repos_orphan) -gt 0
        set -a summary_parts "$dim"(count $repos_orphan)" orphaned$reset"
    end

    echo "  "(string join "$dim · $reset" -- $summary_parts)
    echo "  $dim""Completed in {$elapsed}s$reset"
    echo ""

    # Clean up
    rm -rf $tmp_dir $exec_dir
    functions -e _gg_print_pull_detail

    if test $count_errors -gt 0
        return 1
    end
    return 0
end
