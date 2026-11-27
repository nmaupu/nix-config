# Equivalent of (nmaupu home-services base): everyday packages + qwerty-fr layout.
{ pkgs, config, ... }:

{
  home.packages = with pkgs; [
    bash-completion
    bc
    dig
    curl
    evince
    lm_sensors
    firefox
    git
    htop
    jq
    keep-presence # custom (pkgs/)
    lftp
    neovim
    nodejs # npm, needed for pi and some lsp servers
    p7zip
    perl
    python3
    python3Packages.pip
    python3Packages.requests
    uv # python tools: `uv tool install ruff`, venvs with `uv venv` (replaces pipx)
    openvpn
    qutebrowser
    ripgrep
    fd
    rsync
    recutils
    slack
    strace
    tig
    tree
    ungoogled-chromium
    google-chrome
    unrar
    unzip
    yq-go
    fontconfig
    telegram-desktop
    zoom-us
  ];

  # ~/.config/xkb/qwertyfr.xkb is loaded from ~/.xsession with
  #   xkbcomp -I$XDG_CONFIG_HOME/xkb $XDG_CONFIG_HOME/xkb/qwertyfr.xkb $DISPLAY
  xdg.configFile = {
    "xkb/symbols/qwerty-fr".source = "${pkgs.qwerty-fr}/share/X11/xkb/symbols/us_qwerty-fr";
    "xkb/qwertyfr.xkb".source = ../../files/xkb/qwertyfr.xkb;
    "nvim/init.vim".source = ../../files/nvim/init.vim;
  };

  # npm global installs (pi, ...) go to ~/.npm-global (on PATH, see shells.nix)
  home.file.".npmrc".text = ''
    prefix=${config.home.homeDirectory}/.npm-global
  '';
}
