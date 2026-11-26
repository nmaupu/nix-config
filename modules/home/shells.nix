# zsh (antidote + powerlevel10k), bash, alacritty.
{
  pkgs,
  config,
  lib,
  ...
}:

let
  zshDir = "${config.xdg.configHome}/zsh";
in
{
  home.packages = with pkgs; [
    zsh
    bash
    fzf
    alacritty
  ];

  # Guix: home-environment-variables + zprofile exports
  home.sessionVariables = {
    TERM = "xterm-256color";
    EDITOR = "nvim";
    GIT_EDITOR = "nvim";
    DOCKER_ID = "nmaupu";
    ANSIBLE_NOCOWS = "1";
    GTK_IM_MODULE = "ibus";
    XMODIFIERS = "@im=ibus";
    QT_IM_MODULE = "ibus";
    # https://wiki.archlinux.org/index.php/Xmonad#LibreOffice_-_focus_flicking_between_main_window_and_dialog
    SAL_USE_VCLPLUGIN = "gen";
    # Avoid alacritty scaling the font on DPI
    WINIT_X11_SCALE_FACTOR = "1";
  };

  home.sessionPath = [
    "$HOME/.bin"
    "$HOME/.krew/bin"
    "$HOME/.local/bin"
    "$HOME/.npm-global/bin"
    "$HOME/.local/goenv/bin"
    "$HOME/.local/goenv-data/shims"
  ];

  programs.zsh = {
    enable = true;
    dotDir = zshDir;
    enableCompletion = true;
    autosuggestion.enable = false; # provided by antidote (zsh-users/zsh-autosuggestions)
    syntaxHighlighting.enable = false; # idem

    history = {
      path = "${config.home.homeDirectory}/.zsh_history";
      size = 100000;
      save = 100000;
      extended = true;
      share = true;
      expireDuplicatesFirst = true;
      ignoreAllDups = true;
      saveNoDups = true;
    };

    initContent = builtins.readFile ../../files/zsh/zshrc;

    # Guix zprofile (PATH and exports are handled by home.sessionPath/Variables)
    profileExtra = ''
      # Lock screen only on one screen
      #export XSECURELOCK_SINGLE_AUTH_WINDOW=1
    '';
  };

  # Plugin manager (Guix: antidote package linked to ~/.config/zsh/.antidote)
  programs.zsh.antidote = {
    enable = true;
    useFriendlyNames = true;
    plugins = lib.filter (l: l != "" && !(lib.hasPrefix "#" l)) (
      map (l: lib.trim (lib.head (lib.splitString "#" l))) (
        lib.splitString "\n" (builtins.readFile ../../files/zsh/zsh_plugins.txt)
      )
    );
  };

  programs.bash = {
    enable = true;
    initExtra = builtins.readFile ../../files/bash/bashrc;
    logoutExtra = builtins.readFile ../../files/bash/bash_logout;
  };

  # alacritty.toml imports ~/.config/alacritty/themes/themes/solarized_dark.toml
  xdg.configFile = {
    "zsh/.p10k.zsh".source = ../../files/zsh/p10k;
    "alacritty/alacritty.toml".source = ../../files/alacritty/alacritty.toml;
    "alacritty/themes/themes".source = "${pkgs.alacritty-theme}/share/alacritty-theme";
  };
}
