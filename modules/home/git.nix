{ pkgs, ... }:

{
  home.packages = with pkgs; [
    git
    tig
    meld # merge tool (gitconfig)
  ];

  # Kept as plain files rather than programs.git so the Guix config is reused as-is.
  # ~/.gitconfig-pro is private and not managed here.
  home.file = {
    ".gitconfig".source = ../../files/git/gitconfig;
    ".gitconfig-perso".source = ../../files/git/gitconfig-perso;
  };
}
