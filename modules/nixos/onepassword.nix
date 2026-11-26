# 1Password GUI + CLI. The NixOS modules take care of the setgid helpers,
# the onepassword/onepassword-cli groups and the polkit policy that the Guix
# config set up by hand.
{ pkgs, ... }:

{
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "nmaupu" ];
  };

  # Browser integration: nixpkgs' firefox wrapper exec's `.firefox-wrapped`
  # (Guix equivalent: /etc/1password/custom_allowed_browsers)
  environment.etc."1password/custom_allowed_browsers" = {
    text = ''
      firefox
      .firefox-wrapped
      chromium
      .chromium-wrapped
    '';
    mode = "0755";
  };
}
