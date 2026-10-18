# Neovim / NvChad

## Sessions and unsaved changes

Sessions are saved automatically on exit after opening a file, per working
directory and Git branch, under `stdpath("state")/sessions`.
Restore is explicit so opening a file does not replace your current workspace.
Sessions retain files and window layout, not unsaved buffer contents.

Normal quit and buffer-close commands ask before discarding unsaved changes.
Forced commands such as `:q!` and `:bd!` intentionally bypass confirmation.

## Useful keys

`Space` is the leader key. Press it and wait 300 ms to see available shortcuts.
Which-key also helps with prefixes such as `g` and `Ctrl-w`.

| Keys | Action |
| --- | --- |
| `Space ?` | Show keymaps for the current buffer |
| `Space qs` | Restore session for the current project |
| `Space ql` | Restore the last session |
| `Space qS` | Select a saved session |
| `Space x` | Close the current buffer, with confirmation for unsaved changes |
| `Ctrl-n` | Toggle the file sidebar |
| `Space ff` | Find files |
| `Space fw` | Search text in the project |
| `Space ch` | Open NvChad's cheatsheet |

## Configuration

- The main nvchad repo (NvChad/NvChad) is used as a plugin by this repo.
- So you just import its modules , like `require "nvchad.options" , require "nvchad.mappings"`
- So you can delete the .git from this repo ( when you clone it locally ) or fork it :)

# Credits

1) Lazyvim starter https://github.com/LazyVim/starter as nvchad's starter was inspired by Lazyvim's . It made a lot of things easier!
