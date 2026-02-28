{
  description = "NixOS configurations — andrew's machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ghostty = {
      url = "github:ghostty-org/ghostty";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, niri-flake, stylix, ghostty, agenix, noctalia, ... }@inputs:
  let
    system = "x86_64-linux";

    # Shared module set used by all hosts
    sharedModules = [
      ./modules/common.nix
      ./modules/niri.nix

      niri-flake.nixosModules.niri
      stylix.nixosModules.stylix
      agenix.nixosModules.default

      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit inputs; };
        home-manager.users.andrew = import ./home/default.nix;
        home-manager.sharedModules = [
          agenix.homeManagerModules.default
          noctalia.homeModules.default
        ];
      }
    ];

  in {

    nixosConfigurations = {

      # ── Dell XPS 13 (2015) — dev/test bed ────────────────
      xps13 = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = sharedModules ++ [
          ./hosts/xps13/hardware-configuration.nix
          ./hosts/xps13/configuration.nix
        ];
      };

      # ── ThinkPad P14s Gen 6 — primary workstation ────────
      p14s = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = sharedModules ++ [
          ./hosts/p14s/hardware-configuration.nix
          ./hosts/p14s/configuration.nix
          ./modules/docker.nix
        ];
      };

      # ── Future desktop — uncomment when ready ────────────
      # desktop = nixpkgs.lib.nixosSystem {
      #   inherit system;
      #   specialArgs = { inherit inputs; };
      #   modules = sharedModules ++ [
      #     ./hosts/desktop/hardware-configuration.nix
      #     ./hosts/desktop/configuration.nix
      #     ./modules/docker.nix
      #     ./modules/staging-server.nix
      #   ];
      # };
    };
  };
}
