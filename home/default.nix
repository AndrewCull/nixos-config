{ config, pkgs, inputs, ... }:

{
  imports = [
    ./niri.nix
    ./shell.nix
    ./editors.nix
    ./apps.nix
    ./theme.nix
  ];

  home.username = "andrew";
  home.homeDirectory = "/home/andrew";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;
}
