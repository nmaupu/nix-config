{ inputs, ... }:

{
  imports = [
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-13th-gen
    ./hardware.nix
    ./disko.nix
    ../../modules/nixos
  ];

  networking.hostName = "nmaupu-laptop";

  # Home Manager (user config lives in modules/home)
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak";
    extraSpecialArgs = { inherit inputs; };
    users.nmaupu = {
      imports = [ ../../modules/home ];
      nmaupu.work.enable = true;
    };
  };

  # Do not change after install (see NixOS manual, "stateVersion").
  system.stateVersion = "26.11";
}
