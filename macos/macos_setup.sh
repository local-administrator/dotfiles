#!/bin/bash

echo "Configuring macOS settings"

# Close any open System Settings panes to prevent them from overriding
# the settings being configured
osascript -e 'tell application "System Settings" to quit' 2>/dev/null

###############################################################################
# Finder                                                                      #
###############################################################################

# Use list view in all Finder windows by default
# Codes for the other view modes: `icnv`, `clmv`, `Flwv`
defaults write com.apple.finder FXPreferredViewStyle -string Nlsv

# Disable the warning shown when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Set the Home folder as the default path for new Finder tabs
defaults write com.apple.finder NewWindowTarget -string PfLo
defaults write com.apple.finder NewWindowTargetPath -string "file://$HOME"

# Show the Finder path bar
defaults write com.apple.finder ShowPathbar -bool true

# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string SCcf

# Show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show all file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show status bar (item count and available disk space)
defaults write com.apple.finder ShowStatusBar -bool true

# Show full POSIX path in Finder title bar
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Reduce the spring-loaded folder delay (default 0.5)
defaults write NSGlobalDomain com.apple.springing.delay -float 0.2

# Disable animation for opening the Get Info window
defaults write com.apple.finder DisableAllAnimations -bool true

###############################################################################
# Keyboard & Mouse                                                            #
###############################################################################

# Configure key repeat to be be blazingly fast with a moderate initial delay (ints are in ms)
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Disable natural scrolling (use traditional scrolling direction)
defaults write -g com.apple.swipescrolldirection -bool false

# Disable automatic substitutions that get in the way when typing code
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Enable full keyboard access for all controls
# (e.g. enable Tab in modal dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

###############################################################################
# Trackpad                                                                    #
###############################################################################

# Enable tap to click (tap instead of physical click)
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

###############################################################################
# Screenshots                                                                 #
###############################################################################

# Save screenshots to ~/Screenshots instead of Desktop
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"

# Save screenshots as PNG (lossless)
defaults write com.apple.screencapture type -string png

# Disable shadow on window screenshots
defaults write com.apple.screencapture disable-shadow -bool true

###############################################################################
# Dock                                                                        #
###############################################################################

# Show indicator lights for open applications in the Dock
defaults write com.apple.dock show-process-indicators -bool true

# Make Dock icons of hidden applications translucent
defaults write com.apple.dock showhidden -bool true

# Keep Dock on the bottom
defaults write com.apple.dock orientation -string bottom

# Prevent Dock icons from bouncing
defaults write com.apple.dock no-bouncing -bool true

# Don't show recent applications in Dock
defaults write com.apple.dock show-recents -bool false

# Auto-hide and show the Dock
defaults write com.apple.dock autohide -bool true

# Remove the delay before the Dock auto-hides/shows
defaults write com.apple.dock autohide-delay -float 0

# Speed up the animation for hiding and showing the dock
defaults write com.apple.dock autohide-time-modifier -float 0.25

# Minimize windows using the "genie" effect
defaults write com.apple.dock mineffect -string genie

# Shrink the size of Dock app icons
defaults write com.apple.dock tilesize -int 52

# Clear all apps from the Dock (keep only Finder and Trash)
defaults write com.apple.dock persistent-apps -array
defaults write com.apple.dock persistent-others -array

###############################################################################
# Hot Corners                                                                 #
###############################################################################
# Values: 0=None, 2=Mission Control, 3=Application Windows, 4=Desktop,
#         5=Screen Saver Start, 6=Screen Saver Disable, 10=Put Display to Sleep,
#         11=Launchpad, 12=Notification Center, 13=Lock Screen, 14=Quick Note

# Top-left: Mission Control (show all windows)
defaults write com.apple.dock wvous-tl-corner -int 2
defaults write com.apple.dock wvous-tl-modifier -int 0

# Bottom-left: Lock Screen
defaults write com.apple.dock wvous-bl-corner -int 13
defaults write com.apple.dock wvous-bl-modifier -int 0

###############################################################################
# Speed & Animations                                                          #
###############################################################################

# Disable window open/close animations
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false

# Speed up window resize animation
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

# Speed up Mission Control animation
defaults write com.apple.dock expose-animation-duration -float 0.1

###############################################################################
# Appearance                                                                  #
###############################################################################

# Dark mode
defaults write NSGlobalDomain AppleInterfaceStyle -string Dark

# Accent color: pink (6=Pink, 5=Purple, 4=Blue, 3=Green, 2=Yellow, 1=Orange, 0=Red)
defaults write NSGlobalDomain AppleAccentColor -int 6

# Highlight color: pink
defaults write NSGlobalDomain AppleHighlightColor -string "1.000000 0.749020 0.823529 Pink"

###############################################################################
# Spotlight & Raycast                                                         #
###############################################################################

# Disable Spotlight keyboard shortcuts so Raycast can use Cmd+Space
# Key 64: Show Spotlight search (Cmd+Space)
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 "<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>1048576</integer></array><key>type</key><string>standard</string></dict></dict>"
# Key 65: Show Finder search window (Opt+Cmd+Space)
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 65 "<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>1572864</integer></array><key>type</key><string>standard</string></dict></dict>"
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

###############################################################################
# Menu Bar (Control Center)                                                   #
###############################################################################

# Show Bluetooth in menu bar (18 = always show)
defaults -currentHost write com.apple.controlcenter Bluetooth -int 18

# Show Sound/Volume in menu bar (18 = always show)
defaults -currentHost write com.apple.controlcenter Sound -int 18

###############################################################################
# Miscellaneous                                                               #
###############################################################################

# Use a clear, short, but non-jarring system alert sound
defaults write -g com.apple.sound.beep.sound /System/Library/Sounds/Tink.aiff

# Expand the save and print panels by default
defaults write -g NSNavPanelExpandedStateForSaveMode -bool true
defaults write -g PMPrintingExpandedStateForPrint -bool true

# Automatically quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Disable the crash reporter
defaults write com.apple.CrashReporter DialogType -string none

# Prevent Photos from automatically opening when plugging in an iPhone
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

# Sort Activity Monitor results by highest CPU usage first
defaults write com.apple.ActivityMonitor SortColumn -string CPUUsage
defaults write com.apple.ActivityMonitor SortDirection -int 0

###############################################################################
# Finish                                                                      #
###############################################################################

# Restart affected services to apply changes
killall Dock 2>/dev/null
killall Finder 2>/dev/null
killall ControlCenter 2>/dev/null
killall SystemUIServer 2>/dev/null

echo "Done. Some changes (e.g. appearance, Spotlight shortcut) may require a logout to fully apply."