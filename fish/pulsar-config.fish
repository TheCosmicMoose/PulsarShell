## init starship fastfetch and zoxide on starting the terminal
function fish_greeting
    fastfetch
end

starship init fish | source
zoxide init fish | source
set -gx EDITOR nvim


## functions

function backup --argument filename
    cp $filename $filename.bak
end

## set up aliases
# For use with the Yazi TUI file explorer, open with "y" and upon exiting
# yazi it will set your working directory to the directory that you navigated
# to in yazi.
function y
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	command yazi $argv --cwd-file="$tmp"
	if read -z cwd < "$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
		builtin cd -- "$cwd"
	end
	command rm -f -- "$tmp"
end

thefuck --alias | source
## replace ls with eza for better ls command
alias ls='eza -al --color=always --group-directories-first --icons=always' # preferred listing
alias la='eza -a --color=always --group-directories-first --icons=always'  # all files and dirs
alias ll='eza -l --color=always --group-directories-first --icons=always'  # long format
alias lt='eza -aT --color=always --group-directories-first --icons=always' # tree listing
alias l.="eza -a | grep -e '^\.'"                                          # show only dotfiles

## useful aliases
alias fixpacman="sudo rm /var/lib/pacman/db.lck"
alias tarnow='tar -acf '
alias untar='tar -zxvf '
alias wget='wget -c '
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias hw='hwinfo --short'
# Cleanup orphaned packages
alias cleanup='sudo pacman -Rns (pacman -Qtdq)'
# Quick Ping test
alias testping='ping -c 5 ping.archlinux.org'
# Intall packages from pacman
alias install="sudo pacman -S"
# Enable services with systemd
alias enable="sudo systemctl enable --now"
