{
  description = "NixOS config starting point";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";

    wezterm = {
      url = "github:wez/wezterm/main?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = nixpkgs-stable.legacyPackages.${system};
    pkgs-unstable = nixpkgs.legacyPackages.${system};
  in {
    # using stable version of nixos
    nixosConfigurations.nixos = nixpkgs-stable.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        # Import your main NixOS configuration
        ./hosts/yolan/configuration.nix
        inputs.home-manager.nixosModules.default
        {
          # Overlay to use packages from unstable nixos package manager if needed
          # Just write pkgs.unstable.packagename to use it
          nixpkgs.overlays = [
            (final: prev: {
              unstable = pkgs-unstable;
            })
          ];
        }
      ];
    };
  };
}
