# Bootstrap script for dotfiles on a fresh Windows machine.
# Run with: pwsh -ExecutionPolicy Bypass -File ~/.dotfiles/.dotfiles_meta/windows_bootstrap.ps1
#
# Requires: PowerShell 7+, Developer Mode enabled (or run as Administrator)
# Enable Developer Mode: Settings > System > For Developers > Developer Mode

$ErrorActionPreference = "Continue"

$Dotfiles = "$env:USERPROFILE\.dotfiles"
$Scoopfile = "$Dotfiles\windows\Scoopfile.json"

function Write-Step { param($msg) Write-Host "`n==> $msg" -ForegroundColor Blue }
function Write-Ok   { param($msg) Write-Host "✓ $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "⚠ $msg" -ForegroundColor Yellow }
function Write-Fail { param($msg) Write-Host "✗ $msg" -ForegroundColor Red }

###############################################################################
# 1. Symlink capability
###############################################################################
Write-Step "Checking symlink capability..."
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$devMode = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense -eq 1

if (-not $isAdmin -and -not $devMode) {
    Write-Fail "Symlinks require Administrator or Developer Mode."
    Write-Host "  Enable via: Settings > System > For Developers > Developer Mode"
    Write-Host "  Or re-run this script as Administrator."
    exit 1
}
Write-Ok "Symlink capability confirmed"

###############################################################################
# 2. Scoop
###############################################################################
Write-Step "Checking Scoop..."
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Warn "Scoop not found. Installing..."
    Invoke-RestMethod get.scoop.sh | Invoke-Expression
    $env:PATH = "$env:USERPROFILE\scoop\shims;$env:PATH"
}
Write-Ok "Scoop ready"

###############################################################################
# 3. Dotfiles repo
###############################################################################
Write-Step "Checking dotfiles repo..."
if (-not (Test-Path $Dotfiles)) {
    $choice = Read-Host "Dotfiles not found at $Dotfiles. Clone now? [Y/n]"
    if ($choice -match "^[Nn]$") {
        Write-Fail "Dotfiles required. Clone to $Dotfiles and re-run."
        exit 1
    }
    $repoUrl = Read-Host "Enter repo URL"
    git clone $repoUrl $Dotfiles
}
Write-Ok "Dotfiles at $Dotfiles"

###############################################################################
# 4. Scoop buckets
###############################################################################
Write-Step "Adding Scoop buckets..."
$config = Get-Content $Scoopfile | ConvertFrom-Json
foreach ($bucket in $config.buckets) {
    scoop bucket add $bucket 2>$null
    Write-Ok "Bucket: $bucket"
}

###############################################################################
# 5. Core tools
###############################################################################
Write-Step "Installing core tools..."
foreach ($tool in $config.tools) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        scoop install $tool
    } else {
        Write-Ok "$tool already installed"
    }
}

###############################################################################
# 6. Applications (interactive)
###############################################################################
Write-Step "Application selection..."
$selected = $config.apps | fzf `
    --multi `
    --bind "ctrl-a:select-all" `
    --bind "ctrl-d:deselect-all" `
    --header "TAB: select/deselect | ctrl-a: all | ctrl-d: none | ENTER: confirm" `
    --height=60% `
    --border

if ($selected) {
    foreach ($app in $selected) {
        scoop install $app
    }
    Write-Ok "Applications installed"
} else {
    Write-Warn "No applications selected"
}

###############################################################################
# 7. Fonts
###############################################################################
Write-Step "Fonts..."
$fontChoice = Read-Host "Install all fonts? [Y/n]"
if ($fontChoice -notmatch "^[Nn]$") {
    foreach ($font in $config.fonts) {
        scoop install $font
    }
    Write-Ok "Fonts installed"
} else {
    Write-Warn "Skipped fonts"
}

###############################################################################
# 8. Symlinks
###############################################################################
Write-Step "Creating symlinks..."

function New-Symlink {
    param($Src, $Dst)
    if (-not (Test-Path $Src)) {
        Write-Warn "Source not found, skipping: $Src"
        return
    }
    if (Test-Path $Dst -PathType Any) {
        $existing = Get-Item $Dst -Force
        if ($existing.LinkType -eq "SymbolicLink" -and $existing.Target -eq $Src) {
            Write-Ok "Already linked: $Dst"
            return
        }
        Remove-Item $Dst -Recurse -Force
    }
    $parent = Split-Path $Dst -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    New-Item -ItemType SymbolicLink -Path $Dst -Target $Src | Out-Null
    Write-Ok "Linked: $Dst"
}

$Symlinks = @(
    @{ Src = "$Dotfiles\windows\nushell\config.nu"; Dst = "$env:APPDATA\nushell\config.nu" },
    @{ Src = "$Dotfiles\windows\nushell\env.nu";    Dst = "$env:APPDATA\nushell\env.nu" },
    @{ Src = "$Dotfiles\windows\nushell\custom.nu"; Dst = "$env:APPDATA\nushell\custom.nu" },
    @{ Src = "$Dotfiles\starship\starship.toml";    Dst = "$env:USERPROFILE\.config\starship.toml" },
    @{ Src = "$Dotfiles\git\.gitconfig";            Dst = "$env:USERPROFILE\.gitconfig" },
    @{ Src = "$Dotfiles\git\.gitignore";            Dst = "$env:USERPROFILE\.gitignore" },
    @{ Src = "$Dotfiles\nvim";                      Dst = "$env:LOCALAPPDATA\nvim" },
    @{ Src = "$Dotfiles\bat";                       Dst = "$env:APPDATA\bat" },
    @{ Src = "$Dotfiles\mise";                      Dst = "$env:USERPROFILE\.config\mise" },
    @{ Src = "$Dotfiles\zed\settings.json";         Dst = "$env:APPDATA\Zed\settings.json" }
)

foreach ($link in $Symlinks) {
    New-Symlink -Src $link.Src -Dst $link.Dst
}

###############################################################################
# 9. Windows Terminal settings
###############################################################################
Write-Step "Applying Windows Terminal settings..."
# WT rewrites its settings.json so we copy rather than symlink
$WTPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
if (Test-Path $WTPath) {
    Copy-Item "$Dotfiles\windows\windows_terminal\settings.json" "$WTPath\settings.json" -Force
    Write-Ok "Windows Terminal settings applied"
} else {
    Write-Warn "Windows Terminal not found — install it and copy windows/windows_terminal/settings.json manually"
}

###############################################################################
# 10. Mise trust + install
###############################################################################
Write-Step "Trusting and installing mise tools..."
if (Get-Command mise -ErrorAction SilentlyContinue) {
    mise trust "$env:USERPROFILE\.config\mise\config.toml"
    if (mise install) {
        Write-Ok "mise tools installed"
    } else {
        Write-Warn "mise install had errors — run 'mise install' manually to retry"
    }
} else {
    Write-Warn "mise not found, skipping"
}

###############################################################################
# 11. Git local config
###############################################################################
Write-Step "Git local config..."
$gitLocal = "$env:USERPROFILE\.gitconfig.local"
$setupGit = $true
if (Test-Path $gitLocal) {
    $update = Read-Host "Git local config exists. Update it? [y/N]"
    if ($update -notmatch "^[Yy]$") {
        Write-Ok "Kept existing git local config"
        $setupGit = $false
    }
}
if ($setupGit) {
    $gitEmail = Read-Host "Enter your git email for this device"
    @"
# Device-specific git configuration
# This file is not tracked in version control
[user]
	email = $gitEmail

# ===== Signing (Windows + 1Password) =====
# Uncomment and configure if using 1Password SSH agent on Windows:
# [gpg]
# 	format = ssh
# [gpg "ssh"]
# 	program = C:/Users/$($env:USERNAME)/AppData/Local/1Password/app/8/op-ssh-sign.exe
# [commit]
# 	gpgsign = true
"@ | Set-Content $gitLocal
    Write-Ok "Git local config saved with email: $gitEmail"
}

###############################################################################
# Done
###############################################################################
Write-Host "`n=== Bootstrap complete ===" -ForegroundColor Green
Write-Host "Start Nushell: " -NoNewline
Write-Host "nu" -ForegroundColor Yellow
