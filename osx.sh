#!/usr/bin/env bash

# include my library helpers for colorized echo and require_brew, etc
source ./lib.sh

# Ask for the administrator password upfront
bot "I need you to enter your sudo password so I can install some things:"
sudo -v

# Keep-alive: update existing `sudo` time stamp until `.osx` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

bot "OK, let's roll..."

#####
# install homebrew
#####

running "checking homebrew install"
brew_bin=$(which brew) 2>&1 > /dev/null
if [[ $? != 0 ]]; then
	action "installing homebrew"
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    if [[ $? != 0 ]]; then
    	error "unable to install homebrew, script $0 abort!"
    	exit -1
	fi
fi
ok

running "checking brew-cask install"
output=$(brew tap | grep cask)
if [[ $? != 0 ]]; then
	action "installing brew-cask"
	require_brew caskroom/cask/brew-cask
fi
ok

###############################################################################
#Install command-line tools using Homebrew                                    #
###############################################################################
# Make sure we’re using the latest Homebrew
running "updating homebrew"
brew update
ok

bot "before installing brew packages, we can upgrade any outdated packages."
read -r -p "run brew upgrade? [y|N] " response
if [[ $response =~ ^(y|yes|Y) ]];then
    # Upgrade any already-installed formulae
    action "upgrade brew packages..."
    brew upgrade
    ok "brews updated..."
else
    ok "skipped brew package upgrades.";
fi

bot "installing homebrew command-line tools"


# Install GNU core utilities (those that come with OS X are outdated)
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
require_brew coreutils
# Install some other useful utilities like `sponge`
require_brew moreutils
# Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed
require_brew findutils

# Install Bash 4
# Note: don’t forget to add `/usr/local/bin/bash` to `/etc/shells` before running `chsh`.
#install bash
#install bash-completion

# Install RingoJS and Narwhal
# Note that the order in which these are installed is important; see http://git.io/brew-narwhal-ringo.
#install ringojs
#install narwhal

# Install other useful binaries
require_brew ack
# Beanstalk http://kr.github.io/beanstalkd/
#require_brew beanstalkd
# ln -sfv /usr/local/opt/beanstalk/*.plist ~/Library/LaunchAgents
# launchctl load ~/Library/LaunchAgents/homebrew.mxcl.beanstalk.plist

# docker setup:
#require_brew fig
#require_brew docker
#require_brew boot2docker

# dos2unix converts windows newlines to unix newlines
#require_brew dos2unix
# fortune command--I source this as a better motd :)
#require_brew fortune
#require_brew gawk
# http://www.lcdf.org/gifsicle/ (because I'm a gif junky)
#require_brew gifsicle
# skip those GUI clients, git command-line all the way
require_brew git
# yes, yes, use git-flow, please :)
#require_brew git-flow
# why is everyone still not using GPG?
#require_brew gnupg
# Install GNU `sed`, overwriting the built-in `sed`
# so we can do "sed -i 's/foo/bar/' file" instead of "sed -i '' 's/foo/bar/' file"
require_brew gnu-sed --default-names
#require_brew go
# better, more recent grep
require_brew homebrew/dupes/grep
require_brew hub
require_brew imagemagick
require_brew imagesnap
# jq is a JSON grep
#require_brew jq
# http://maven.apache.org/
#require_brew maven
#require_brew memcached
#require_brew nmap
#require_brew node
#require_brew redis
# better/more recent version of screen
#require_brew homebrew/dupes/screen
#require_brew tig
#require_brew tree
#require_brew ttyrec
# better, more recent vim
require_brew vim --override-system-vi
require_brew watch
# Install wget with IRI support
require_brew wget --enable-iri

bot "if you would like to start memcached at login, run this:"
echo "ln -sfv /usr/local/opt/memcached/*.plist ~/Library/LaunchAgents"
bot "if you would like to start memcached now, run this:"
echo "launchctl load ~/Library/LaunchAgents/homebrew.mxcl.memcached.plist"

###############################################################################
# Native Apps (via brew cask)                                                 #
###############################################################################
bot "installing GUI tools via homebrew casks..."
brew tap caskroom/versions > /dev/null 2>&1

require_cask bartender
require_cask bettertouchtool
require_cask boom
require_cask calibre
require_cask controlplane
require_cask dropbox
require_cask firefox
require_cask gfxcardstatus
require_cask github
require_cask google-chrome
require_cask istat-menus
require_cask iterm2
require_cask jdownloader
require_cask launchbar
require_cask little-snitch
require_cask nvalt
require_cask omnigraffle
require_cask perian
require_cask rescuetime
require_cask scrivener
require_cask slack
require_cask skype
require_cask textexpander
require_cask the-unarchiver
require_cask trim-enabler
require_cask unrarx
require_cask vlc
require_cask whatpulse
require_cask xquartz

bot "Alright, cleaning up homebrew cache..."
# Remove outdated versions from the cellar
brew cleanup > /dev/null 2>&1
bot "All clean"

###############################################################################
bot "Configuring General System UI/UX..."
###############################################################################
# Set computer name (as done via System Preferences → Sharing)
sudo scutil --set ComputerName "Turing"
sudo scutil --set HostName "Turing"
sudo scutil --set LocalHostName "Turing"
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "Turing"

running "Menu bar: disable transparency"
defaults write NSGlobalDomain AppleEnableMenuBarTransparency -bool false;ok

"running "Menu bar: Hide the Battery and User icons"
for domain in ~/Library/Preferences/ByHost/com.apple.systemuiserver.*; do
	defaults write "${domain}" dontAutoLoad -array \
		"/System/Library/CoreServices/Menu Extras/Battery.menu" \
		"/System/Library/CoreServices/Menu Extras/User.menu"
done;
defaults write com.apple.systemuiserver menuExtras -array \
	"/System/Library/CoreServices/Menu Extras/Bluetooth.menu" \
	"/System/Library/CoreServices/Menu Extras/AirPort.menu" \
	"/System/Library/CoreServices/Menu Extras/Volume.menu" \
	"/System/Library/CoreServices/Menu Extras/Clock.menu"
ok

running "Set sidebar icon size to medium"
defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 2;ok

running "Always show scrollbars"
defaults write NSGlobalDomain AppleShowScrollBars -string "Always";ok
# Possible values: `WhenScrolling`, `Automatic` and `Always`

running "Increase window resize speed for Cocoa applications"
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001;ok

running "Expand save panel by default"
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true;ok

running "Expand print panel by default"
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true;ok

running "Save to disk (not to iCloud) by default"
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false;ok

running "Disable an iCloud-centric open panel when opening an application that supports syncing documents and data"
defaults write -g NSShowAppCentricOpenPanelInsteadOfUntitledFile -bool false;ok

running "Disable the “Are you sure you want to open this application?” dialog"
defaults write com.apple.LaunchServices LSQuarantine -bool false;ok

running "Remove duplicates in the “Open With” menu (also see 'lscleanup' alias)"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user;ok

running "Set Help Viewer windows to non-floating mode"
defaults write com.apple.helpviewer DevMode -bool true;ok

running "Check for software updates daily, not just once per week"
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1;ok

running "Disable Notification Center and remove the menu bar icon"
launchctl unload -w /System/Library/LaunchAgents/com.apple.notificationcenterui.plist > /dev/null 2>&1;ok

###############################################################################
bot "Trackpad, mouse, keyboard, Bluetooth accessories, and input"
###############################################################################

running "Trackpad: enable tap to click for this user and for the login screen"
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1;ok

running "Disable “natural” (Lion-style) scrolling"
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false;ok

running "Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)"
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3;ok

running "Disable press-and-hold for keys in favor of key repeat"
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false;ok

running "Set a blazingly fast keyboard repeat rate"
defaults write NSGlobalDomain KeyRepeat -int 0;ok

running "Set language and text formats (english/US)"
defaults write NSGlobalDomain AppleLanguages -array "en" "zh_CN"
defaults write NSGlobalDomain AppleLocale -string "en_US@currency=USD"
defaults write NSGlobalDomain AppleMeasurementUnits -string "Inches"
defaults write NSGlobalDomain AppleMetricUnits -bool false;ok

running "Set the timezone; see sudo systemsetup -listtimezones for other values"
sudo systemsetup -settimezone "America/Chicago" > /dev/null;ok

running "Disable auto-correct"
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false;ok

###############################################################################
bot "Configuring the Screen"
###############################################################################

running "Save screenshots to the desktop"
defaults write com.apple.screencapture location -string "${HOME}/Desktop";ok

running "Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)"
defaults write com.apple.screencapture type -string "png";ok

running "Disable shadow in screenshots"
defaults write com.apple.screencapture disable-shadow -bool true;ok

running "Enable subpixel font rendering on non-Apple LCDs"
defaults write NSGlobalDomain AppleFontSmoothing -int 2;ok

###############################################################################
bot "Finder Configs"
###############################################################################

running "Set home folder as the default location for new Finder windows"
# For other paths, use `PfLo` and `file:///full/path/here/`
defaults write com.apple.finder NewWindowTarget -string "PfLo"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/";ok

running "Show all filename extensions"
defaults write NSGlobalDomain AppleShowAllExtensions -bool true;ok

running "Show status bar"
defaults write com.apple.finder ShowStatusBar -bool true;ok

running "Show path bar"
defaults write com.apple.finder ShowPathbar -bool true;ok

running "Allow text selection in Quick Look"
defaults write com.apple.finder QLEnableTextSelection -bool true;ok

running "Display full POSIX path as Finder window title"
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true;ok

running "When performing a search, search the current folder by default"
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf";ok

running "Disable the warning when changing a file extension"
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false;ok

running "Avoid creating .DS_Store files on network volumes"
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true;ok

running "Use column view in all Finder windows by default"
# Four-letter codes for the other view modes: `icnv`, `clmv`, `Flwv`
defaults write com.apple.finder FXPreferredViewStyle -string "clmv";ok

running "Show the ~/Library folder"
chflags nohidden ~/Library;ok

###############################################################################
bot "Dock & Dashboard"
###############################################################################

running "Change minimize/maximize window effect to scale"
defaults write com.apple.dock mineffect -string "scale";ok

running "Show indicator lights for open applications in the Dock"
defaults write com.apple.dock show-process-indicators -bool true;ok

running "Speed up Mission Control animations"
defaults write com.apple.dock expose-animation-duration -float 0.1;ok

running "Remove the auto-hiding Dock delay"
defaults write com.apple.dock autohide-delay -float 0;ok
running "Remove the animation when hiding/showing the Dock"
defaults write com.apple.dock autohide-time-modifier -float 0;ok

running "Automatically hide and show the Dock"
defaults write com.apple.dock autohide -bool true;ok

running "Make Dock icons of hidden applications translucent"
defaults write com.apple.dock showhidden -bool true;ok

running "Enable the 2D Dock"
defaults write com.apple.dock no-glass -bool true;ok

bot "Configuring Hot Corners"
# Possible values:
#  0: no-op
#  2: Mission Control
#  3: Show application windows
#  4: Desktop
#  5: Start screen saver
#  6: Disable screen saver
#  7: Dashboard
# 10: Put display to sleep
# 11: Launchpad
# 12: Notification Center

running "Top left screen corner"
defaults write com.apple.dock wvous-tl-corner -int 0
defaults write com.apple.dock wvous-tl-modifier -int 0;ok
running "Top right screen corner"
defaults write com.apple.dock wvous-tr-corner -int 0
defaults write com.apple.dock wvous-tr-modifier -int 0;ok
running "Bottom left screen corner → Dashboard"
defaults write com.apple.dock wvous-bl-corner -int 7
defaults write com.apple.dock wvous-bl-modifier -int 0
running "Bottom right screen corner → Show application windows"
defaults write com.apple.dock wvous-br-corner -int 0
defaults write com.apple.dock wvous-br-modifier -int 0;ok

###############################################################################
bot "Configuring Safari & WebKit"
###############################################################################

running "Set Safari’s home page to ‘about:blank’ for faster loading"
defaults write com.apple.Safari HomePage -string "about:blank";ok

running "Prevent Safari from opening ‘safe’ files automatically after downloading"
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false;ok

running "Hide Safari’s bookmarks bar by default"
defaults write com.apple.Safari ShowFavoritesBar -bool false;ok

running "Hide Safari’s sidebar in Top Sites"
defaults write com.apple.Safari ShowSidebarInTopSites -bool false;ok

running "Disable Safari’s thumbnail cache for History and Top Sites"
defaults write com.apple.Safari DebugSnapshotsUpdatePolicy -int 2;ok

running "Enable Safari’s debug menu"
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true;ok

running "Remove useless icons from Safari’s bookmarks bar"
defaults write com.apple.Safari ProxiesInBookmarksBar "()";ok

running "Enable the Develop menu and the Web Inspector in Safari"
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true;ok

###############################################################################
bot "Spotlight"
###############################################################################

running "Change indexing order and disable some file types from being indexed"
defaults write com.apple.spotlight orderedItems -array \
	'{"enabled" = 1;"name" = "DIRECTORIES";}' \
	'{"enabled" = 1;"name" = "DOCUMENTS";}' \
	'{"enabled" = 1;"name" = "PDF";}' \
	'{"enabled" = 1;"name" = "PRESENTATIONS";}' \
	'{"enabled" = 1;"name" = "SPREADSHEETS";}' \
	'{"enabled" = 1;"name" = "MESSAGES";}' \
	'{"enabled" = 0;"name" = "APPLICATIONS";}' \
	'{"enabled" = 0;"name" = "SYSTEM_PREFS";}' \
	'{"enabled" = 0;"name" = "FONTS";}' \
	'{"enabled" = 0;"name" = "CONTACT";}' \
	'{"enabled" = 0;"name" = "EVENT_TODO";}' \
	'{"enabled" = 0;"name" = "IMAGES";}' \
	'{"enabled" = 0;"name" = "BOOKMARKS";}' \
	'{"enabled" = 0;"name" = "MUSIC";}' \
	'{"enabled" = 0;"name" = "MOVIES";}' \
	'{"enabled" = 0;"name" = "SOURCE";}' \
	'{"enabled" = 0;"name" = "MENU_DEFINITION";}' \
	'{"enabled" = 0;"name" = "MENU_OTHER";}' \
	'{"enabled" = 0;"name" = "MENU_CONVERSION";}' \
	'{"enabled" = 0;"name" = "MENU_EXPRESSION";}' \
	'{"enabled" = 0;"name" = "MENU_WEBSEARCH";}' \
	'{"enabled" = 0;"name" = "MENU_SPOTLIGHT_SUGGESTIONS";}';ok
	
running "Load new settings before rebuilding the index"
killall mds > /dev/null 2>&1;ok

running "Make sure indexing is enabled for the main volume"
sudo mdutil -i on / > /dev/null;ok

###############################################################################
bot "Terminal & iTerm2"
###############################################################################

running "Installing the Monokai theme for iTerm (opening file)"
open "./configs/Monokai.itermcolors";ok

running "Don’t display the annoying prompt when quitting iTerm"
defaults write com.googlecode.iterm2 PromptOnQuit -bool false;ok

###############################################################################
bot "Address Book, Dashboard, iCal, TextEdit, and Disk Utility"
###############################################################################

running "Enable the debug menu in Address Book"
defaults write com.apple.addressbook ABShowDebugMenu -bool true;ok

running "Use plain text mode for new TextEdit documents"
defaults write com.apple.TextEdit RichText -int 0;ok

running "Open and save files as UTF-8 in TextEdit"
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4;ok

running "Enable the debug menu in Disk Utility"
defaults write com.apple.DiskUtility DUDebugMenuEnabled -bool true
defaults write com.apple.DiskUtility advanced-image-options -bool true;ok

###############################################################################
bot "Google Chrome & Google Chrome Canary"
###############################################################################

running "Disable Swipe controls for Google Chrome"
defaults write com.google.Chrome.plist AppleEnableSwipeNavigateWithScrolls -bool FALSE;ok

###############################################################################
# Kill affected applications                                                  #
###############################################################################
bot "OK. Note that some of these changes require a logout/restart to take effect. Killing affected applications (so they can reboot)...."
for app in "Address Book" "Calendar" "Contacts" "cfprefsd" \
	"Dock" "Finder" "Google Chrome" "iTerm2" "Messages" "Safari" "SystemUIServer" \
	"iCal" "Terminal"; do
	killall "${app}" > /dev/null 2>&1
done
