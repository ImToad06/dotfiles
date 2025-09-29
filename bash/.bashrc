# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# ============================== Aliases ==============================
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias ..='cd ..'
alias vim='nvim'
alias fetch='fastfetch'

# ============================== Functions ==============================
pacs() {
    paru -Slq | fzf --multi --preview 'paru -Si {1}' | xargs -ro paru -S
}

# ============================== Path ==============================
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
source /usr/share/nvm/init-nvm.sh
