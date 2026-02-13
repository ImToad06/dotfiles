# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Enable bash-completion
if [[ -r /usr/share/bash-completion/bash_completion ]]; then
    source /usr/share/bash-completion/bash_completion
fi

# ============================== Aliases ==============================
alias ls='exa -l --icons'
alias grep='grep --color=auto'
alias ..='cd ..'
alias vim='nvim'
alias fetch='fastfetch'
alias suspend='systemctl suspend'

# ============================== Path ==============================
export EDITOR=nvim
export PATH="$HOME/.local/bin:$PATH"

# ============================== Prompt ==============================
eval "$(starship init bash)"

# ============================== Fzf ==============================
eval "$(fzf --bash)"
export FZF_DEFAULT_OPTS="
    --color=fg:#908caa,bg:#191724,hl:#ebbcba
    --color=fg+:#e0def4,bg+:#26233a,hl+:#ebbcba
    --color=border:#403d52,header:#31748f,gutter:#191724
    --color=spinner:#f6c177,info:#9ccfd8
    --color=pointer:#c4a7e7,marker:#eb6f92,prompt:#908caa"

# ============================== NodeJS ==============================
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
