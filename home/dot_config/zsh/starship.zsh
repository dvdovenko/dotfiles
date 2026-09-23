#! /bin/zsh

# Starship
if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
else
  print -u2 'starship not found; install it to enable the prompt.'
fi
