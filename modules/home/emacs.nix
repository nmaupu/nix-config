# Doom Emacs. The doom-emacs script clones doom + the config repo on first run
# (the config must stay writable, so it is not managed by nix).
{ pkgs, ... }:

let
  emacsPkg = (pkgs.emacsPackagesFor pkgs.emacs).emacsWithPackages (epkgs: [
    epkgs.vterm # prebuilt so doom's :term vterm does not need cmake at runtime
  ]);
in
{
  home.packages = with pkgs; [
    emacsPkg
    shellcheck
    shfmt
    gopls
    delve
    gomodifytags
    golangci-lint
    terraform-ls
    sbcl
    jansson
    # doom deps
    ripgrep
    fd
    cmake
    gnumake
    libtool
  ];

  services.emacs = {
    enable = true;
    package = emacsPkg;
    client.enable = true;
    # Guix shepherd: emacs --fg-daemon
  };

  home.file.".local/bin/doom-emacs" = {
    source = ../../files/emacs/doom-emacs;
    executable = true;
  };
}
