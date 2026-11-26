# Overlay with packages missing from nixpkgs (Guix: nmaupu/packages/*.scm)
final: prev: {
  polybar-themes = final.callPackage ./polybar-themes.nix { };
  polybar-themes-fonts = final.callPackage ./polybar-themes-fonts.nix { };
  goenv = final.callPackage ./goenv.nix { };
  keep-presence = final.callPackage ./keep-presence.nix { };
  tmux-tpm = final.callPackage ./tmux-tpm.nix { };
  pi-extensions = final.callPackage ./pi-extensions.nix { };
  anthropic-skills = final.callPackage ./anthropic-skills.nix { };
}
