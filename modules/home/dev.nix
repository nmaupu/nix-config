# Dev tooling (non work-specific): toolchains, goenv/tfenv, gpg.
{ pkgs, config, ... }:

let
  goenvRoot = ".local/goenv";
  goenvData = ".local/goenv-data";
  tfenvData = ".local/tfenv-data";
in
{
  home.packages = with pkgs; [
    gcc
    gnumake
    cmake
    pkg-config
    binutils
    cargo
    rustc
    go-jsonnet
    protobuf
    pre-commit
    openjdk
    gnupg
    pinentry-rofi
    proxychains-ng
    tfenv
    android-studio
    ollama
  ];

  home.sessionVariables = {
    TFENV_CONFIG_DIR = "${config.home.homeDirectory}/${tfenvData}";
    GOENV_ROOT = "${config.home.homeDirectory}/${goenvData}";
  };

  # goenv needs a directory literally named "goenv" (see pkgs/goenv.nix);
  # ~/.local/goenv/bin is on PATH (shells.nix)
  home.file."${goenvRoot}".source = pkgs.goenv;

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry-rofi;
  };
  programs.gpg.enable = true;
}
