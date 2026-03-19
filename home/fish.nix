{ config, pkgs, ... }:

{
  programs.fish = {
    enable = true;

    shellAbbrs = {
      cd = "z";

      # nix
      rebuild = "sudo nixos-rebuild switch --flake /etc/nixos-config#(hostname)";
      update = "nix flake update /etc/nixos-config";

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
      o = "obsidian";

      # navigation shortcuts
      nxc = "z etc/nixos-config";
    };

    functions = {
      # yazi — cd to last dir on exit
      y = ''
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        command yazi $argv --cwd-file="$tmp"
        if read -z cwd < "$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
            builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
      '';

      # ssh — load key from bitwarden vault
      ssh-unlock = ''
        bw unlock --check &>/dev/null; or bw login
        set -x BW_SESSION (bw unlock --raw)
        set -l tmpask (mktemp)
        begin
          echo "#!/bin/sh"
          echo "export BW_SESSION=$BW_SESSION"
          echo "bw get password 'SSH GitHub'"
        end > $tmpask
        chmod +x $tmpask
        env SSH_ASKPASS=$tmpask SSH_ASKPASS_REQUIRE=force ssh-add ~/.ssh/github
        rm -f $tmpask
      '';

      # multi-line helpers
      cdc = "mkdir -p $argv && cd $argv";
      cdb = "for i in (seq 1 $argv); cd ..; end";
    };

    interactiveShellInit = ''
      set fish_greeting
      set EDITOR hx

      fish_add_path ~/.npm-global/bin
      fish_add_path ~/.local/bin
    '';
  };
}
