{ inputs, ... }:

{
  imports = [
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-13th-gen
    ./hardware.nix
    ./disko.nix
    ../../modules/nixos
  ];

  networking.hostName = "nmaupu-laptop";

  # Do not change after install (see NixOS manual, "stateVersion").
  system.stateVersion = "26.11";
}
