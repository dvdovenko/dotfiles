# Local git overrides

Files here are loaded by `~/.gitconfig` via `[include]` / `[includeIf]`. Only
`*.example` files are tracked in git; the real `*.gitconfig` files are
gitignored and stay machine-local.

Setup on a new machine:

```bash
cd ~/.config/git/conf.d
for f in *.example; do cp "$f" "${f%.example}"; done
```

Then edit each `*.gitconfig` with the real name/email/ssh key for that
identity. `default.gitconfig` is your fallback identity (loaded always);
the others only apply under their matching `gitdir` in
`~/.gitconfig`.

Adding a new identity: drop a new `<name>.gitconfig.example` here, add a
matching `[includeIf "gitdir:..."] path = ~/.config/git/conf.d/<name>.gitconfig`
block to `~/.gitconfig`, then run the copy step above again.
