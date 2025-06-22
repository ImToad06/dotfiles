# ~/.bashrc: executed by bash(1) for non-login shells.
# This file sets up the environment and customizes the shell.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Source system-wide bashrc if it exists
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# Shell options
# Append to the history file, don't overwrite it
shopt -s histappend
# Check the window size after each command
shopt -s checkwinsize

# Environment variables
# Add user's private bin directories to PATH
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi
export EDITOR=vim          # Set default editor
export HISTSIZE=10000       # Number of commands to remember
export HISTFILESIZE=10000   # Size of history file
export HISTCONTROL=ignoredups:ignorespace  # Ignore duplicates and spaces
export PATH="$HOME/.local/bin:$PATH"

# Enable programmable completion
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi
# Color support for commands
if ls --color > /dev/null 2>&1; then
    alias ls='ls --color=auto'    # Linux
elif [ "$(uname)" = "Darwin" ]; then
    export CLICOLOR=1             # macOS
    export LSCOLORS=ExFxBxDxCxegedabagacad
fi
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias diff='diff --color=auto'

# Useful aliases
alias ll='ls -la'      # List all in long format
alias la='ls -A'       # List almost all
alias l='ls -CF'       # List in columns
alias cd..='cd ..'     # Go up one directory
alias ..='cd ..'       # Shortcut to go up
alias ...='cd ../..'   # Go up two directories
alias fetch='fastfetch'
alias update='paru'
alias install='paru'
alias vim='nvim'

# Git aliases
alias gs='git status'  # Check repository status
alias ga='git add'     # Stage files
alias gc='git commit'  # Commit changes
alias gp='git push'    # Push to remote
alias gl='git pull'    # Pull from remote

# Starship
eval "$(starship init bash)"

# Fzf
eval "$(fzf --bash)"
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
--color=selected-bg:#45475A \
--color=border:#313244,label:#CDD6F4"
bind '"\C-f":"tmux-sessionizer\n"'
