{
  description = "VM image of a PXE boot server with dnsmasq";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixos-generators.url = "github:nix-community/nixos-generators";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    nixos-generators,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];

      flake = {
        packages."x86_64-linux".default = nixos-generators.nixosGenerate {
          system = "x86_64-linux";
          format = "qcow";
          modules = [
            ./configuration.nix
          ];
        };
      };
    };
}
