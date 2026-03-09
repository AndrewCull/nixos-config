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
  };

  outputs = { self, nixpkgs, home-manager, stylix, sops-nix, ... }@inputs:
  let
    system = "x86_64-linux";

    sharedModules = [
      ./modules/common.nix
      ./modules/niri.nix
      ./modules/hhkb.nix

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
    };
  };
}
