{ pkgs, ... }:

{
  # Guix pinned helm 3.17 / k9s 0.50 / kind 0.27 / kubectl 1.32; pin here with
  # an overlay if a specific version is ever needed.
  home.packages = with pkgs; [
    kubectl
    kubernetes-helm
    k9s
    kind
    krew # plugins land in ~/.krew (on PATH)
  ];
}
