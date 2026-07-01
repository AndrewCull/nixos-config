{ config, pkgs, ... }:

{
  programs.fish = {
    enable = true;

    shellAbbrs = {
      cd = "z";

      # nix
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
      # nixos-rebuild for the current host
      rebuild = "sudo nixos-rebuild switch --flake /etc/nixos-config#(hostname) $argv";

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
        set -x NODE_NO_WARNINGS 1
        bw unlock --check &>/dev/null; or bw login
        set -x BW_SESSION (bw unlock --raw)
        set -l tmpask (mktemp)
        begin
          echo "#!/bin/sh"
          echo "export NODE_NO_WARNINGS=1"
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

      # netcheck — split WiFi link vs upstream internet health, to tell at a
      # glance whether a video stutter is local WiFi or the Starlink uplink.
      # Gateway = router/Starlink dish (should be a few ms); Internet = the
      # satellite hop. Usage: `netcheck` or `netcheck <host>`.
      netcheck = ''
        set -l count 10
        set -l target 8.8.8.8
        test -n "$argv[1]"; and set target $argv[1]

        set_color cyan; echo "── netcheck ──"; set_color normal

        # WiFi link quality (signal + negotiated rate)
        set -l w (nmcli -t -f IN-USE,SSID,SIGNAL,RATE dev wifi 2>/dev/null | string match -r '^\*.*')
        if test -n "$w"
            set -l p (string split ':' -- $w)
            echo "WiFi     : $p[2]  ·  signal $p[3]/100  ·  $p[4]"
        end

        # gateway = your router / Starlink dish; target = the wider internet
        set -l gw (ip route 2>/dev/null | awk '/^default/{print $3; exit}')

        for pair in "Gateway $gw" "Internet $target"
            set -l label (string split ' ' -- $pair)[1]
            set -l host (string split ' ' -- $pair)[2]
            test -z "$host"; and continue
            set -l out (ping -c $count -i 0.2 -W 1 $host 2>/dev/null | string collect)
            set -l loss (echo $out | grep -oE '[0-9.]+% packet loss' | grep -oE '^[0-9.]+')
            set -l avg (echo $out | awk -F'/' '/rtt|round-trip/{printf "%.0f", $5}')

            set -l verdict
            if test -z "$avg"
                set_color red; set verdict "✗ unreachable"
            else if test -n "$loss"; and test "$loss" != "0"
                set_color yellow; set verdict "⚠ $loss% loss"
            else if test "$avg" -gt 150
                set_color yellow; set verdict "⚠ high latency"
            else
                set_color green; set verdict "✓ ok"
            end
            printf "%-9s: %4s ms   loss %-4s  %s\n" $label "$avg" "$loss%" "$verdict"
            set_color normal
        end
      '';
    };

    interactiveShellInit = ''
      set fish_greeting
      set EDITOR hx

      fish_add_path ~/.npm-global/bin
      fish_add_path ~/.local/bin

      mkdir -p ~/.local/bin
      ln -sf ~/Code/agema_os/os-cli/target/release/os ~/.local/bin/os
    '';
  };
}
