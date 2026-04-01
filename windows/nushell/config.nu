$env.config = {
    show_banner: false
    edit_mode: vi

    history: {
        max_size: 100_000
        sync_on_enter: true
        file_format: "sqlite"
        isolation: true
    }

    completions: {
        algorithm: "fuzzy"
        case_sensitive: false
        quick: true
    }

    shell_integration: {
        osc2: true
        osc7: true
        osc8: true
        osc9_9: false
        osc133: true
        osc633: true
    }
}

# Aliases
alias ll  = lsd -la
alias la  = lsd -a
alias l   = lsd
alias cat = bat
alias vim = nvim
alias lg  = lazygit
alias g   = git
alias z   = __zoxide_z   # zoxide directory jumping

# Update all tools
def update [] {
    print "Updating Scoop packages..."
    scoop update *
    print "Updating mise tools..."
    mise upgrade
    print "Done."
}

# Source generated init scripts (created by env.nu; skip if not yet generated)
source ($nu.home-path | path join ".cache" "starship" "init.nu")
source ($nu.home-path | path join ".zoxide.nu")
source ($nu.home-path | path join ".mise.nu")

# Custom functions — edit this file to add your own
source custom.nu
