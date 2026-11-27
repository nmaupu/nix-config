# xmonad session: ~/.xsession, xmonad config + scripts, polybar, picom, dunst,
# rofi/dmenu, greenclip, screen lock. xmonad itself (with ghc + contrib) comes
# from the NixOS module (modules/nixos/desktop.nix).
{ pkgs, config, ... }:

{
  home.packages = with pkgs; [
    acpi
    arandr
    blueman
    picom
    xsecurelock
    xss-lock
    xclip
    xmodmap
    xrandr
    xrdb
    xsetroot
    psmisc # killall, used by ~/.config/polybar/launch.sh to restart the bar
    xkbcomp
    setxkbmap
    xmessage # useful when recompiling xmonad in case of errors
    alsa-utils
    brightnessctl
    haskellPackages.greenclip
    dmenu
    dunst
    flameshot
    fzf
    polybar
    rofi
    pasystray
    pwvucontrol
    lxappearance
    gopass # rofiPass binding in xmonad.hs
  ];

  xdg.configFile = {
    "xmonad/xmonad.hs".source = ../../files/xmonad/xmonad.hs;
    "xmonad/scripts" = {
      source = ../../files/xmonad/scripts; # scripts are +x in git
      recursive = true;
    };
    "dunst/dunstrc".source = ../../files/dunst/dunstrc;
    "picom/picom.conf".source = ../../files/picom/picom.conf;
    "flameshot/flameshot.ini".source = ../../files/flameshot/flameshot.ini;
    # xmonad.hs: spawnOnce "$HOME/.config/polybar/launch.sh --forest"
    "polybar".source = pkgs.polybar-themes;
  };

  # ~/.xsession (Guix: files/xsession/.xsession), run by the "home-manager"
  # session declared in modules/nixos/desktop.nix.
  xsession = {
    enable = true;
    windowManager.command = "xmonad";
    initExtra = ''
      exec >> $HOME/.xsession.log 2>> $HOME/.xsession.err
      echo "xsession : $(date)"
      echo 1>&2 "xsession : $(date)"

      # Adding missing resolution for C49RG90 wide monitor
      xrandr --newmode "4096x1440_30.00" 234.17 4096 4288 4712 5328 1440 1441 1444 1465 -HSync +Vsync
      xrandr --newmode "5120x1440_30.00" 292.75  5120 5360 5888 6656  1440 1443 1453 1468 -hsync +vsync
      xrandr --addmode DP-1-1 "4096x1440_30.00"
      xrandr --addmode DP-1-1 "5120x1440_30.00"
      xrandr --addmode HDMI-1 "5120x1440_30.00"
      xrandr --addmode HDMI-1 "4096x1440_30.00"

      # Paint the root window, otherwise the last closed window stays "ghosted"
      # on screen (nothing redraws the empty root). Colour = colBG in xmonad.hs.
      xsetroot -solid '#0f0f0f' -cursor_name left_ptr

      mkdir -p ~/.logs

      ## systray programs
      pasystray &>~/.logs/pasystray.log &
      blueman-applet &>~/.logs/blueman-applet.log &
      telegram-desktop -startintray &>~/.logs/telegram-desktop.log &
      1password --silent &>~/.logs/1password.log &
      slack --startup &

      # Screen lock
      xset s 180 10
      XSECURELOCK_COMPOSITE_OBSCURER=0 \
          XSECURELOCK_SHOW_HOSTNAME=0 \
          XSECURELOCK_SHOW_USERNAME=0 \
          XSECURELOCK_PASSWORD_PROMPT=cursor \
          XSECURELOCK_SHOW_DATETIME=1 \
          xss-lock -n "${pkgs.xsecurelock}/libexec/xsecurelock/dimmer" -l -- xsecurelock &

      # Set keyboard map (no space after -I or it won't load)
      xkbcomp -I$XDG_CONFIG_HOME/xkb $XDG_CONFIG_HOME/xkb/qwertyfr.xkb "$DISPLAY"
      # Caps lock = Escape (setting it AFTER loading keyboard)
      setxkbmap -option caps:escape
      # Remap shift+esc to ~
      xmodmap -e 'keysym Escape = Escape asciitilde Escape'
    '';
  };

  # Guix home shepherd services
  systemd.user.services.greenclip = {
    Unit = {
      Description = "Greenclip clipboard manager daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.haskellPackages.greenclip}/bin/greenclip daemon";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
