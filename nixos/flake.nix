{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";

  in { 
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
          # Import your main NixOS configuration
          ./configuration.nix

          # If you use Home Manager as a NixOS module:
          # (home-manager.nixosModules.home-manager)
        ];
    };
  };
}
