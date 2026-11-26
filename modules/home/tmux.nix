{ pkgs, ... }:

{
  home.packages = [ pkgs.tmux ];

  home.file = {
    ".tmux.conf".source = ../../files/tmux/tmux.conf;
    ".tmux.theme.conf".source = ../../files/tmux/tmux.theme.conf;
    # tpm installs the other plugins next to it (prefix + I), ~/.tmux/plugins stays writable
    ".tmux/plugins/tpm".source = pkgs.tmux-tpm;
  };
}
