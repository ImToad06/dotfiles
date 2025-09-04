# Bash config

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# ---------- Environment variables ----------
export EDITOR=nvim
export HISTCONTROL=ignoredups:ignorespace
export PATH="$HOME/.local/bin:$PATH"

# ---------- Aliases ----------
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias diff='diff --color=auto'

alias ll='ls -la'
alias la='ls -A'
alias ..='cd ..'

alias fetch='fastfetch'
alias vim='nvim'


# ---------- Prompt ----------
eval "$(starship init bash)"

# ---------- Fzf ----------
eval "$(fzf --bash)"
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
--color=selected-bg:#45475A \
--color=border:#313244,label:#CDD6F4"

# ---------- sessionizer ----------
bind '"\C-f":"tmux-sessionizer\n"'
