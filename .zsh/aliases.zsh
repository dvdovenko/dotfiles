# Alias
# ---
#
alias a="ansible"
alias ap="ansible-playbook"
alias dt="datree"

# ALIAS COMMANDS
# alias ls="exa --icons --group-directories-first"
# alias ll="exa --icons --group-directories-first -l"
alias g="goto"
alias grep='grep --color'
alias cat="bat"
alias ls="eza"

# alias cpr="code $HOME/Developers/projects"

# alias air='$(go env GOPATH)/bin/air'
# alias swag='$(go env GOPATH)/bin/swag'

alias vim="nvim"
alias npmpublic="npm config set registry https://registry.npmjs.org/ && npm config get registry"
alias npmlocal="npm set registry http://localhost:4873; npm config get registry"
alias guid="uuidgen"
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
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
