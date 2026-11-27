{ ... }:

{
  imports = [
    ./base.nix
    ./shells.nix
    ./git.nix
    ./tmux.nix
    ./wm.nix
    ./emacs.nix
    ./dev.nix
    ./k8s.nix
    ./pi.nix
    ./work.nix
    ./scripts.nix
  ];

  home = {
    username = "nmaupu";
    homeDirectory = "/home/nmaupu";
    # Do not change after install.
    stateVersion = "26.11";
  };

  xdg.enable = true;

  programs.home-manager.enable = true;
}
