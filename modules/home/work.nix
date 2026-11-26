# Work-specific tools, toggled with nmaupu.work.enable (hosts/*/default.nix).
{
  pkgs,
  lib,
  config,
  ...
}:

let
  cfg = config.nmaupu.work;
  gcloud = pkgs.google-cloud-sdk.withExtraComponents (
    with pkgs.google-cloud-sdk.components;
    [
      gke-gcloud-auth-plugin
      minikube
    ]
  );
in
{
  options.nmaupu.work.enable = lib.mkEnableOption "work tools (gcloud, argocd, vault, ...)";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      gcloud
      talosctl
      vault
      terragrunt
      git-secret
      skaffold
      sops
      docker-compose
      argocd
      argonaut
      temporal-cli
      code-cursor
      postman
      kubectl-view-allocations
    ];

    # No gcloud path/completion.zsh.inc sourcing needed (Guix zshrc did it):
    # nixpkgs puts gcloud on PATH and its zsh completion in fpath (_gcloud).
  };
}
