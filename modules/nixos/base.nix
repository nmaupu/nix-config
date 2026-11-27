# Equivalent of (nmaupu systems base): locale, user, nix daemon, base packages.
{ pkgs, ... }:

{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # Lets ~/.config/nix/nix.conf add substituters/netrc-file (work caches)
      trusted-users = [
        "root"
        "nmaupu"
      ];
      substituters = [
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
      auto-optimise-store = true;
    };

    # Guix: `guix gc -d 2m -F 50G` every day at 5AM
    gc = {
      automatic = true;
      dates = "05:00";
      options = "--delete-older-than 60d";
    };
  };

  nixpkgs.config.allowUnfree = true;

  time.timeZone = "Europe/Paris";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocales = [ "ja_JP.EUC-JP/EUC-JP" ];
  };

  console.keyMap = "us";

  users = {
    users.nmaupu = {
      isNormalUser = true;
      description = "Nicolas Maupu";
      home = "/home/nmaupu";
      shell = pkgs.zsh;
      group = "users"; # primary group, like on Guix
      extraGroups = [
        "wheel"
        "networkmanager"
        "kvm"
        "libvirtd"
        "tty"
        "input"
        "docker"
        "lp"
        "audio"
        "video"
        "scanner"
      ];
    };
  };

  # Needed for zsh as login shell (sets up /etc/zshrc, completions path, ...)
  programs.zsh.enable = true;

  # Run unpatched dynamic binaries (goenv's go toolchains, tfenv's terraform,
  # npm prebuilt natives such as pi-lens' ast-grep, ...). Replaces the Guix
  # LD_LIBRARY_PATH wrappers.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      openssl
      libxml2
      icu
    ];
  };

  programs.dconf.enable = true;

  environment.systemPackages = with pkgs; [
    bluez
    brightnessctl
    exfat
    git
    gvfs
    libva-utils
    lvm2
    ntfs3g
    nfs-utils
    vim
    wget
    curl
    usbutils
    pciutils
  ];

  # /bin/bash for scripts hardcoding it (Guix: extra-special-file "/bin/bash")
  # NixOS already provides /bin/sh and /usr/bin/env.
  systemd.tmpfiles.rules = [
    "L+ /bin/bash - - - - ${pkgs.bash}/bin/bash"
  ];
}
