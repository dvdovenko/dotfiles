#! /bin/zsh

# fnm
# --shell zsh: this file only ever runs under zsh, but fnm's own process-tree
# based autodetection can fail in some container/wrapper setups ("Can't infer
# shell!") — pass it explicitly rather than relying on detection.
eval "$(fnm env --use-on-cd --shell zsh)"
