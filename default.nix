{ config, pkgs, inputs, ... }:

{
  imports = with builtins;
    let
      # auto-import every .nix in this directory except default.nix
      files = attrNames (readDir ./.);
      nixFiles = filter (f: f != "default.nix" && builtins.match ".*\\.nix" f != null) files;
    in
      map (f: ./${f}) nixFiles;

  home.username = "andrew";
  home.homeDirectory = "/home/andrew";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;
}
