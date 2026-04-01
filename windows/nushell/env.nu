# Environment variables
$env.EDITOR = "nvim"
$env.VISUAL = "nvim"
$env.PAGER = "less"

# Starship
if (which starship | is-not-empty) {
    mkdir ($env.USERPROFILE | path join ".cache" "starship")
    starship init nu | save -f ($env.USERPROFILE | path join ".cache" "starship" "init.nu")
}

# Zoxide (replaces z)
if (which zoxide | is-not-empty) {
    zoxide init nushell | save -f ($env.USERPROFILE | path join ".zoxide.nu")
}

# Mise
if (which mise | is-not-empty) {
    mise activate nu | save -f ($env.USERPROFILE | path join ".mise.nu")
}
