{
  description = "nmaupu's NixOS + Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative disk layout (LUKS2 > LVM). Only acts when `disko` is run
    # explicitly, see README.
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      disko,
      nixos-hardware,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      overlays = [ (import ./pkgs) ];

      mkHost =
        hostname:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            { nixpkgs.overlays = overlays; }
            disko.nixosModules.disko
            ./hosts/${hostname}
          ];
        };
    in
    {
      nixosConfigurations = {
        nmaupu-laptop = mkHost "nmaupu-laptop";
      };

      # User config, applied on its own with `update-home` (not part of the
      # NixOS system: no home-manager NixOS module).
      homeConfigurations."nmaupu@nmaupu-laptop" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system overlays;
          config.allowUnfree = true;
        };
        extraSpecialArgs = { inherit inputs; };
        modules = [
          ./modules/home
          { nmaupu.work.enable = true; }
        ];
      };

      # Expose custom packages: `nix build .#polybar-themes`
      packages.${system} =
        let
          pkgs = import nixpkgs {
            inherit system overlays;
            config.allowUnfree = true;
          };
        in
        {
          inherit (pkgs)
            polybar-themes
            polybar-themes-fonts
            goenv
            keep-presence
            tmux-tpm
            pi-extensions
            anthropic-skills
            ;
        };

      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt;
    };
}
