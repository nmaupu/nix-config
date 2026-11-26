# X11 + SDDM + xmonad, fonts, keyboard, screen locking.
{ pkgs, lib, ... }:

{
  services.xserver = {
    enable = true;

    xkb = {
      layout = "us";
      variant = "altgr-intl";
      model = "thinkpad";
    };

    # xmonad installed system-wide so `xmonad --recompile` (mod+q) finds ghc and
    # the libraries; the config stays in ~/.config/xmonad/xmonad.hs (home-manager).
    windowManager.xmonad = {
      enable = true;
      enableContribAndExtras = true;
      extraPackages = hp: [
        hp.raw-strings-qq
        hp.regex-base
        hp.regex-tdfa
      ];
    };

    # Session running ~/.xsession (written by home-manager, modules/home/wm.nix)
    displayManager.session = [
      {
        manage = "window";
        name = "home-manager";
        start = ''
          ${pkgs.runtimeShell} $HOME/.xsession &
          waitPID=$!
        '';
      }
    ];

    excludePackages = [ pkgs.xterm ];
  };

  services.displayManager = {
    sddm.enable = true;
    defaultSession = "none+home-manager";
  };

  # Touchpad tapping (Guix xorg InputClass)
  services.libinput = {
    enable = true;
    touchpad.tapping = true;
  };

  # xsecurelock needs a PAM service; xss-lock itself is started from ~/.xsession
  # (keeps the XSECURELOCK_* env vars of the session).
  security.pam.services.xsecurelock = { };

  # gnome-keyring unlocked at login
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;

  fonts = {
    enableDefaultPackages = true;
    fontconfig.enable = true;
    packages = with pkgs; [
      nerd-fonts.commit-mono
      nerd-fonts.iosevka
      nerd-fonts.fantasque-sans-mono
      nerd-fonts.noto
      nerd-fonts.droid-sans-mono
      nerd-fonts.terminess-ttf
      nerd-fonts.jetbrains-mono
      source-han-serif
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      polybar-themes-fonts # custom (pkgs/)
    ];
  };

  environment.systemPackages = with pkgs; [
    xsecurelock
    xss-lock
    xset
    xkbcomp
    xmodmap
    xrandr
    xrdb
    setxkbmap
    xmessage
    lxappearance
  ];
}
