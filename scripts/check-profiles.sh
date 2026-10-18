#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
target="$(mktemp -d)"
trap 'rm -rf "$target"' EXIT
mkdir -p "$target/bin"
cat > "$target/bin/uname" <<'EOF'
#!/bin/sh
case "$1" in
  -s) echo "${PROFILE_TEST_OS:-Linux}" ;;
  -m) echo "${PROFILE_TEST_ARCH:-x86_64}" ;;
esac
EOF
chmod +x "$target/bin/uname"

for arch in x86_64 aarch64; do
  for profile in default slim core; do
    suffix=-slim
    [[ "$profile" != core ]] || suffix=''
    profile_args=()
    [[ "$profile" = default ]] || profile_args=("DOTFILES_PROFILE=$profile")
    for action in vps-build vps-switch vps-nix-switch nix-install; do
      output="$(env -u DOTFILES_PROFILE PATH="$target/bin:$PATH" PROFILE_TEST_ARCH="$arch" make -s -n -C "$repo" "$action" "${profile_args[@]}")"
      [[ "$output" == *"vps@$arch-linux$suffix"* ]]
      if [[ "$action" = vps-nix-switch || "$action" = nix-install ]]; then
        [[ "$output" != *apply-dotfiles.sh* && "$output" != *install-plugins.sh* ]]
      fi
    done
  done
  for profile in full invalid; do
    if PATH="$target/bin:$PATH" make -s -n -C "$repo" vps-build DOTFILES_PROFILE="$profile" > "$target/output" 2>&1; then
      echo "VPS $profile profile unexpectedly accepted" >&2
      exit 1
    fi
    grep -q 'Linux supports only DOTFILES_PROFILE: slim core' "$target/output"
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
  if [[ "$script" = setup-homebrew ]]; then
    printf 'echo "brew-args $*" >> "$BOOTSTRAP_TEST_LOG"\n' >> "$target/repo/scripts/$script.sh"
  fi
  chmod +x "$target/repo/scripts/$script.sh"
done
for cmd in nix git sudo; do
  printf '#!/bin/sh\necho "%s $*" >> "$BOOTSTRAP_TEST_LOG"\n' "$cmd" > "$target/bin/$cmd"
  chmod +x "$target/bin/$cmd"
done
for os in Linux Darwin; do
  for profile in default core $(if [[ "$os" = Linux ]]; then echo slim; else echo full; fi); do
    suffix=''
    [[ "$profile" != slim && !( "$profile" = default && "$os" = Linux ) ]] || suffix=-slim
    [[ "$profile" != full ]] || suffix=-full
    profile_env=()
    [[ "$profile" = default ]] || profile_env=("DOTFILES_PROFILE=$profile")
    for mode in '' --nix-only; do
      : > "$BOOTSTRAP_TEST_LOG"
      args=()
      [[ -z "$mode" ]] || args=("$mode")
      env -u DOTFILES_PROFILE HOME="$target/home" PATH="$target/bin:$PATH" PROFILE_TEST_OS="$os" \
        DOTFILES_DIR="$target/repo" "${profile_env[@]}" bash "$repo/scripts/bootstrap.sh" "${args[@]}" > "$target/output"
      if [[ "$os" = Linux ]]; then
        grep -q "vps@x86_64-linux$suffix --impure" "$BOOTSTRAP_TEST_LOG"
        if [[ "$profile" = core && -z "$mode" ]]; then
          grep -qx setup-homebrew "$BOOTSTRAP_TEST_LOG"
          grep -qx "brew-args bundle" "$BOOTSTRAP_TEST_LOG"
        else
          ! grep -qx setup-homebrew "$BOOTSTRAP_TEST_LOG"
        fi
      else
        grep -q "danylo-mbp$suffix" "$BOOTSTRAP_TEST_LOG"
        grep -qx setup-homebrew "$BOOTSTRAP_TEST_LOG"
      fi
      for script in apply-dotfiles install-plugins; do
        if [[ -z "$mode" ]]; then
          grep -qx "$script" "$BOOTSTRAP_TEST_LOG"
        else
          ! grep -qx "$script" "$BOOTSTRAP_TEST_LOG"
        fi
      done
    done
  done
done
output="$(make -s -n -C "$repo" dotfiles-apply)"
[[ "$output" == *apply-dotfiles.sh* && "$output" != *'nix run'* ]]
if grep -q 'nvim' "$repo/scripts/install-plugins.sh"; then
  echo 'plugin installation must defer Neovim to first launch' >&2
  exit 1
fi
echo 'install stages: Nix only, config only, combined bootstrap; Neovim deferred'
for profile in default core full; do
  suffix=""
  [ "$profile" != full ] || suffix=-full
  profile_args=()
  [[ "$profile" = default ]] || profile_args=("DOTFILES_PROFILE=$profile")
  output="$(env -u DOTFILES_PROFILE PATH="$target/bin:$PATH" PROFILE_TEST_OS=Darwin make -s -n -C "$repo" darwin-build "${profile_args[@]}")"
  [[ "$output" == *"danylo-mbp$suffix.system"* ]]
done

# Invalid profiles fail before installing tools or updating the checkout.
for os in Linux Darwin; do
  rejected=full
  [[ "$os" != Darwin ]] || rejected=slim
  for profile in "$rejected" invalid; do
    : > "$BOOTSTRAP_TEST_LOG"
    if PATH="$target/bin:$PATH" PROFILE_TEST_OS="$os" DOTFILES_PROFILE="$profile" bash "$repo/scripts/bootstrap.sh" > "$target/output" 2>&1; then
      echo "$os bootstrap $profile profile unexpectedly accepted" >&2
      exit 1
    fi
    grep -q "$os supports only DOTFILES_PROFILE=" "$target/output"
    [[ ! -s "$BOOTSTRAP_TEST_LOG" ]]
  done
done
echo 'profiles: Linux slim/core (default slim), macOS core/full (default core)'

if [ "${1:-}" = --nix ]; then
  cd "$repo"
  nix eval --impure --json --expr '
    let
      f = builtins.getFlake (toString ./nix);
      check = system: let
        pkgs = import f.inputs.nixpkgs { inherit system; config.allowUnfree = true; };
        names = profile: map pkgs.lib.getName (import ./nix/shared/cli-packages.nix { inherit pkgs profile; });
        slim = names "slim";
        expectedSlim = map pkgs.lib.getName (with pkgs; [ gitMinimal openssh curl less zsh tmux starship chezmoi coreutils gnumake gnused nano ripgrep fd fzf jq ]);
        core = names "core";
        full = names "full";
        homeOnly = [ "gnupg" "automake" "libtool" ];
      in
        assert slim == expectedSlim;
        assert builtins.all (p: builtins.elem p core) [ "devbox" "git-lfs" "gnused" ];
        assert builtins.all (p: builtins.elem p core == pkgs.stdenv.hostPlatform.isLinux) [ "neovim" "tmux" "starship" ];
        assert builtins.all (p: !(builtins.elem p full)) [ "codex" "claude-code" "uv" "rustup" "go" "python3" "pipx" ];
        assert builtins.all (p: !(builtins.elem p slim)) [ "neovim" "git-lfs" "delta" "bat" ];
        assert builtins.all (p: !(builtins.elem p core) && builtins.elem p full) homeOnly;
        assert builtins.all (p: builtins.elem p full) core;
        { inherit system; slimPackages = builtins.length slim; corePackages = builtins.length core; fullPackages = builtins.length full; };
    in
      assert builtins.all (p: builtins.elem p (map (b: b.name) f.darwinConfigurations.danylo-mbp.config.homebrew.brews))
        [ "neovim" "tmux" "starship" "uv" "go" "node" "fnm" ];
      assert builtins.attrNames f.darwinConfigurations == [ "danylo-mbp" "danylo-mbp-full" ];
      assert builtins.attrNames f.homeConfigurations == [ "vps@aarch64-linux" "vps@aarch64-linux-slim" "vps@x86_64-linux" "vps@x86_64-linux-slim" ];
      assert builtins.all (system: let
        slim = f.homeConfigurations."vps@${system}-slim".config;
        core = f.homeConfigurations."vps@${system}".config;
      in !slim.programs.home-manager.enable && !slim.manual.manpages.enable
        && !slim.manual.html.enable && !slim.manual.json.enable
        && !slim.targets.genericLinux.enable && !slim.systemd.user.enable
        && core.programs.home-manager.enable && core.targets.genericLinux.enable
        && core.systemd.user.enable) [ "x86_64-linux" "aarch64-linux" ];
      map check [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ]
  '
fi
