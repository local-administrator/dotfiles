# Environment variables
$env.EDITOR = "nvim"
$env.VISUAL = "nvim"
$env.PAGER = "less"

# Starship
mkdir ($env.USERPROFILE | path join ".cache" "starship")
starship init nu | save -f ($env.USERPROFILE | path join ".cache" "starship" "init.nu")

# Zoxide (replaces z)
zoxide init nushell | save -f ($env.USERPROFILE | path join ".zoxide.nu")

# Mise
mise activate nu | save -f ($env.USERPROFILE | path join ".mise.nu")
