{
  description = "NixOS configurations — andrew's machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # niri-flake — niri 26.04 in nixpkgs (+ libinput 1.31) lost input on this
    # ThinkPad after the 2026-05-13 upgrade. Pull niri from upstream so we can
    # pin to a working version independent of the nixpkgs release cadence.
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pinned old nixpkgs solely to source libinput 1.29.2. libinput 1.31 (in
    # current nixpkgs unstable) stops enumerating keyboard + touchpad on this
    # ThinkPad P14s Gen 6 AMD. Overlay below pulls just libinput from here.
    # Commit 68a8af93 is the last nixpkgs revision that shipped libinput 1.29.2.
    nixpkgs-libinput = {
      url = "github:NixOS/nixpkgs/68a8af93ff4297686cb68880845e61e5e2e41d92";
    };
  };

  outputs = { self, nixpkgs, home-manager, stylix, sops-nix, niri, nixpkgs-libinput, ... }@inputs:
  let
    system = "x86_64-linux";

    sharedModules = [
      ./modules/common.nix
      ./modules/niri.nix
      ./modules/hhkb.nix

      niri.nixosModules.niri
      sops-nix.nixosModules.sops
      stylix.nixosModules.stylix

      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "bak";
        home-manager.extraSpecialArgs = { inherit inputs; };
        home-manager.users.andrew = import ./home;
      }
    ];
  in {
    nixosConfigurations = {

      p14s = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = sharedModules ++ [
          ./hosts/p14s/hardware-configuration.nix
          ./hosts/p14s/configuration.nix
          ./modules/docker.nix
        ];
      };

      darkstar = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = sharedModules ++ [
          ./hosts/darkstar/hardware-configuration.nix
          ./hosts/darkstar/configuration.nix
          ./modules/docker.nix
        ];
      };
    };
  };
}
