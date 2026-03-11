function update -d "Update all package managers and tools"
    set_color green
    echo '🔄 Starting system update...'
    set_color normal
    
    # Homebrew
    if type -q brew
        set_color blue
        echo '📦 Updating Homebrew...'
        set_color normal
        brew update
        brew upgrade
        brew cleanup
    end
    
    # mise (version manager)
    if type -q mise
        set_color blue
        echo '🔧 Updating mise tools...'
        set_color normal
        mise upgrade
    end
    
    # Fisher (fish plugin manager)
    if type -q fisher
        set_color blue
        echo '🐠 Updating Fish plugins...'
        set_color normal
        fisher update
        fish_update_completions
    end
    
    # macOS system updates (optional, show what's available)
    if test (uname) = "Darwin"
        set_color blue
        echo '💻 Checking macOS updates...'
        set_color normal
        softwareupdate --list
        set_color yellow
        echo "💡 Run 'sudo softwareupdate -ia' to install macOS updates"
        set_color normal
    end
    
    set_color green
    echo '✅ Update complete!'
    set_color normal
end
