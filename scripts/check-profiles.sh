#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
target="$(mktemp -d)"
trap 'rm -rf "$target"' EXIT
mkdir -p "$target/bin"
cat > "$target/bin/uname" <<'EOF'
#!/bin/sh
case "$1" in
  -s) echo Linux ;;
  -m) echo "${PROFILE_TEST_ARCH:-x86_64}" ;;
esac
EOF
chmod +x "$target/bin/uname"

for arch in x86_64 aarch64; do
  for action in vps-build vps-switch vps-nix-switch nix-install; do
    output="$(PATH="$target/bin:$PATH" PROFILE_TEST_ARCH="$arch" make -s -n -C "$repo" "$action" DOTFILES_PROFILE=core)"
    [[ "$output" == *"vps@$arch-linux"* ]]
    if [[ "$action" = vps-nix-switch || "$action" = nix-install ]]; then
      [[ "$output" != *apply-dotfiles.sh* && "$output" != *install-plugins.sh* ]]
    fi
    if PATH="$target/bin:$PATH" make -s -n -C "$repo" "$action" DOTFILES_PROFILE=full > "$target/output" 2>&1; then
      echo 'VPS full profile unexpectedly accepted' >&2
      exit 1
    fi
    grep -q 'VPS supports only DOTFILES_PROFILE=core' "$target/output"
  done
done

# Exercise bootstrap modes without installing packages or changing the host.
mkdir -p "$target/repo/.git" "$target/repo/scripts" "$target/home"
mkdir -p "$target/home/.nix-profile/etc/profile.d"
# source_nix may prepend the host Nix profile; restore the mocked commands.
printf 'export PATH="%s/bin:$PATH"\n' "$target" > "$target/home/.nix-profile/etc/profile.d/nix.sh"
export BOOTSTRAP_TEST_LOG="$target/bootstrap.log"
for script in setup-homebrew apply-dotfiles install-plugins; do
  printf '#!/bin/sh\necho %s >> "$BOOTSTRAP_TEST_LOG"\n' "$script" > "$target/repo/scripts/$script.sh"
  chmod +x "$target/repo/scripts/$script.sh"
done
for cmd in nix git; do
  printf '#!/bin/sh\necho "%s $*" >> "$BOOTSTRAP_TEST_LOG"\n' "$cmd" > "$target/bin/$cmd"
  chmod +x "$target/bin/$cmd"
done
for mode in '' --nix-only; do
  : > "$BOOTSTRAP_TEST_LOG"
  args=()
  [[ -z "$mode" ]] || args=("$mode")
  HOME="$target/home" PATH="$target/bin:$PATH" DOTFILES_DIR="$target/repo" DOTFILES_PROFILE=core \
    bash "$repo/scripts/bootstrap.sh" "${args[@]}" > "$target/output"
  grep -q 'home-manager -- switch' "$BOOTSTRAP_TEST_LOG"
  for script in setup-homebrew apply-dotfiles install-plugins; do
    if [[ -z "$mode" ]]; then
      grep -qx "$script" "$BOOTSTRAP_TEST_LOG"
    elif grep -qx "$script" "$BOOTSTRAP_TEST_LOG"; then
      echo "nix-only unexpectedly ran $script" >&2
      exit 1
    fi
  done
done
output="$(make -s -n -C "$repo" dotfiles-apply)"
[[ "$output" == *apply-dotfiles.sh* && "$output" != *'nix run'* ]]
if grep -q 'nvim' "$repo/scripts/install-plugins.sh"; then
  echo 'plugin installation must defer Neovim to first launch' >&2
  exit 1
fi
echo 'install stages: Nix only, config only, combined bootstrap; Neovim deferred'
for profile in core full; do
  suffix=""
  [ "$profile" = core ] || suffix=-full
  output="$(make -s -n -C "$repo" darwin-build DOTFILES_PROFILE="$profile")"
  [[ "$output" == *"danylo-mbp$suffix.system"* ]]
done

# Reject full before installing Nix/Homebrew or updating the dotfiles checkout.
if PATH="$target/bin:$PATH" DOTFILES_PROFILE=full bash "$repo/scripts/bootstrap.sh" > "$target/output" 2>&1; then
  echo 'Linux bootstrap full profile unexpectedly accepted' >&2
  exit 1
fi
grep -q 'Linux/VPS supports only DOTFILES_PROFILE=core' "$target/output"
echo 'profiles: VPS core only on both architectures, macOS core/full'

if [ "${1:-}" = --nix ]; then
  cd "$repo"
  nix eval --impure --json --expr '
    let
      f = builtins.getFlake (toString ./nix);
      check = system: let
        pkgs = import f.inputs.nixpkgs { inherit system; config.allowUnfree = true; };
        names = profile: map pkgs.lib.getName (import ./nix/shared/cli-packages.nix { inherit pkgs profile; });
        core = names "core";
        full = names "full";
        homeOnly = [ "devbox" "codex" "claude-code" "gnupg" "uv" "rustup" "go" "python3" "pipx" ];
      in
        assert builtins.all (p: !(builtins.elem p core) && builtins.elem p full) homeOnly;
        assert builtins.all (p: builtins.elem p full) core;
        { inherit system; corePackages = builtins.length core; fullPackages = builtins.length full; };
    in
      assert builtins.attrNames f.homeConfigurations == [ "vps@aarch64-linux" "vps@x86_64-linux" ];
      map check [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ]
  '
fi
