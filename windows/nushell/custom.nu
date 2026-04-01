# Custom functions and aliases
# Add your own definitions here — this file is sourced from config.nu

# Source device-specific config (not tracked in git)
let local_config = ($nu.home-path | path join ".config" "nushell" "config.local.nu")
if ($local_config | path exists) {
    source $local_config
}
