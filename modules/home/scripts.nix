# update-nix / update-system / update-home: replacements for the Guix
# update-channels / update-system / update-home scripts (guix-config .bin).
#
#   update-nix      nix flake update (lock file only, nothing is applied)
#   update-system   nixos-rebuild switch  (NixOS: kernel, services, xmonad, ...)
#   update-home     home-manager switch   (user: packages, dotfiles, .xsession)
#
# Extra arguments are passed to the underlying command (--show-trace, ...).
# `--dry` only builds, without switching. `update-system --home` also runs
# update-home afterwards (`--dry` applies to both).
# Repository location: $NIX_CONFIG_DIR (default ~/work/perso/nix-config).
{ pkgs, inputs, ... }:

let
  header = ''
    repo="''${NIX_CONFIG_DIR:-$HOME/work/perso/nix-config}"
    msg() { printf '\033[1;32m%s \033[1;34m%s\033[1;32m...\033[0m\n' "$1" "$2"; }
    [ -f "$repo/flake.nix" ] || { echo "No flake.nix in $repo (set NIX_CONFIG_DIR)" >&2; exit 1; }
  '';

  update-nix = pkgs.writeShellApplication {
    name = "update-nix";
    runtimeInputs = [
      pkgs.git
      pkgs.nix
    ];
    text = ''
      ${header}
      msg "Updating flake inputs of" "$repo"
      nix flake update --flake "$repo" "$@"
      git -C "$repo" --no-pager diff --stat -- flake.lock || true
      echo "Inputs updated! Not applied yet: run update-system and/or update-home."
    '';
  };

  update-system = pkgs.writeShellApplication {
    name = "update-system";
    runtimeInputs = [ pkgs.nvd ];
    text = ''
      ${header}
      host="$(cat /proc/sys/kernel/hostname)"
      action=switch
      home=0
      # --dry / --home can be given in any order, before the extra arguments
      while [ $# -gt 0 ]; do
        case "$1" in
          --dry) action=dry-build; shift ;;
          --home) home=1; shift ;;
          *) break ;;
        esac
      done

      msg "Updating system" "$host"
      old="$(readlink -f /run/current-system)"
      sudo nixos-rebuild "$action" --flake "$repo#$host" "$@"
      if [ "$action" = switch ]; then
        nvd diff "$old" "$(readlink -f /run/current-system)" || true
      fi

      # Extra arguments only go to nixos-rebuild
      if [ "$home" = 1 ]; then
        if [ "$action" = switch ]; then
          ${update-home}/bin/update-home
        else
          ${update-home}/bin/update-home --dry
        fi
      fi
    '';
  };

  update-home = pkgs.writeShellApplication {
    name = "update-home";
    runtimeInputs = [
      pkgs.nvd
      inputs.home-manager.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
    text = ''
      ${header}
      host="$(cat /proc/sys/kernel/hostname)"
      action=switch
      if [ "''${1:-}" = "--dry" ]; then action=build; shift; fi

      msg "Updating $USER home on" "$host"
      profile="$HOME/.local/state/nix/profiles/home-manager"
      old="$(readlink -f "$profile" 2>/dev/null || true)"
      # build: no ./result symlink in the repo
      if [ "$action" = build ]; then
        home-manager build --no-out-link --flake "$repo#$USER@$host" "$@"
      else
        home-manager switch -b hm-bak --flake "$repo#$USER@$host" "$@"
        [ -n "$old" ] && nvd diff "$old" "$(readlink -f "$profile")" || true
      fi
    '';
  };
in
{
  home.packages = [
    update-nix
    update-system
    update-home
  ];
}
