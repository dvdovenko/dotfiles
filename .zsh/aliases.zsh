#! /bin/zsh

# Alias
# ---
#
alias vim="nvim"
alias dt="datree"
alias grep='grep --color'

if command -v bat >/dev/null 2>&1; then
    alias cat="bat"
else
    # alias cat="cat"
fi

if command -v eza >/dev/null 2>&1; then
    alias ls='eza'
    alias ll='eza -lah'
    alias la='eza -lah'
    alias l='eza -lah --git'
    alias tree='eza --tree'
else
    alias ll='ls -lah'
    alias l='ls -CF'
    alias ls='ls -h --color=auto'
    alias la='ls -lah --color=auto'
fi

# alias air='$(go env GOPATH)/bin/air'
# alias swag='$(go env GOPATH)/bin/swag'

alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"

alias npmpublic="npm config set registry https://registry.npmjs.org/ && npm config get registry"
alias npmlocal="npm set registry http://localhost:4873; npm config get registry"

alias df='df -h'
alias psaux='ps aux | grep -i'
alias digs='dig +short'

alias uuid="uuidgen | tr '[:upper:]' '[:lower:]'"
alias guid="uuid"
alias gensalt32="xxd -g 2 -l 32 -p /dev/random | tr -d '\n'"
alias gensalt16="xxd -g 2 -l 16 -p /dev/random | tr -d '\n'"
alias gensalt8="xxd -g 2 -l 8 -p /dev/random | tr -d '\n'"

codex-tmux-experimental() {
  # use current folder name for a readable session label
  local session="codex-${PWD##*/}"
  OPENAI_BASE_URL=http://0.0.0.0:8787/v1 tmux new-session -A -s "$session" -c "$PWD" "codex"
}


codex-tmux() {
  # use current folder name for a readable session label
  local session="codex-${PWD##*/}"
  tmux new-session -A -s "$session" -c "$PWD" "codex"
}

copilot-tmux() {
  # use current folder name for a readable session label
  local session="copilot-${PWD##*/}"
  tmux new-session -A -s "$session" -c "$PWD" "copilot"
}

claude-tmux-experimental() {
  # use current folder name for a readable session label
  local session="claude-${PWD##*/}"
  ANTHROPIC_BASE_URL=http://0.0.0.0:8787 tmux new-session -A -s "$session" -c "$PWD" "claude"
}

claude-tmux() {
  # use current folder name for a readable session label
  local session="claude-${PWD##*/}"
  tmux new-session -A -s "$session" -c "$PWD" "claude"
}

alias vibecode="claude-tmux-experimental"
alias vibecode-claude="claude-tmux-experimental"
alias vibecode-claude-stable="claude-tmux"
alias vibecode-codex="codex-tmux-experimental"
alias vibecode-codex-stable="codex-tmux"

export DOPPLER_TOKEN="$(pass show doppler/token)"
