{
  description = "NixOS configuration for Chuwi Minibook X and related services";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs = {
    nixpkgs,
    nixos-hardware,
    ...
  }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
  in {
    nixosModules = {
      default = import ./modules/nixos/default.nix {
        inherit nixos-hardware;
      };
    };

    packages = {
      x86_64-linux = {
        tablet-mode-daemon = pkgs.callPackage ./pkgs/tablet-mode-daemon.nix {};
        minibookx-troubleshoot = pkgs.callPackage ./pkgs/minibookx-troubleshoot.nix {};
      };
    };
  };
}
