{ config, pkgs, ... }:

{
  programs.fish = {
    enable = true;

    shellAliases = {
      # nix
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config#(hostname)";
      update = "nix flake update ~/nixos-config";

      # git
      gs = "git status";
      gp = "git push";
      gc = "git commit";
      gd = "git diff";

      # docker
      dc = "docker compose";
      dcu = "docker compose up -d";
      dcd = "docker compose down";
      dcl = "docker compose logs -f";

      # modern replacements
      cat = "bat";
      ls = "eza";
      ll = "eza -la --icons";
      lt = "eza -la --icons --tree --level=2";

      # misc
      rd = "rm -rf";
    };

    shellAbbrs = {
      cd = "z";
    };

    functions = {
      cdc = "mkdir -p $argv && cd $argv";
      cdb = "for i in (seq 1 $argv); cd ..; end";
    };

    interactiveShellInit = ''
      set fish_greeting
      set EDITOR hx

      fish_add_path ~/.npm-global/bin
    '';
  };
}
