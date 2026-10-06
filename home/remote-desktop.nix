{ config, pkgs, lib, osConfig, ... }:

let
  isDarkstar = osConfig.networking.hostName == "darkstar";

  # Viewer side (every host but darkstar): forward darkstar's wayvnc socket over
  # SSH to a local port and open it in wlvncc. The remote command powers the
  # monitors back on (swayidle turns them off when idle, which leaves nothing
  # to capture; an ssh session has no NIRI_SOCKET, hence the glob), then
  # `sleep 10` holds the tunnel open just long enough for wlvncc to connect —
  # ssh stays alive until that forwarded connection closes, so quitting the
  # viewer tears the tunnel down.
  darkstar-desktop = pkgs.writeShellScriptBin "darkstar-desktop" ''
    port=5901
    ${pkgs.openssh}/bin/ssh -f -o ExitOnForwardFailure=yes \
      -L 127.0.0.1:$port:/run/user/1000/wayvnc.sock darkstar \
      "sh -c 'NIRI_SOCKET=\$(echo /run/user/1000/niri.*.sock) niri msg action power-on-monitors; sleep 10'" \
      || exit 1
    exec ${pkgs.wlvncc}/bin/wlvncc 127.0.0.1 $port
  '';
in
{
  # ── Remote desktop into darkstar ────────────────────
  # wayvnc serves the live niri session on a unix socket in $XDG_RUNTIME_DIR
  # (mode 0700) instead of a TCP port: nothing listens on the network and VNC
  # needs no password of its own — the only way in is an SSH session as andrew
  # (Tailscale SSH, ACL-authed), which `darkstar-desktop` uses to forward it.
  systemd.user.services.wayvnc = lib.mkIf isDarkstar {
    Unit = {
      Description = "wayvnc (VNC server on a private unix socket)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      Requisite = [ "graphical-session.target" ];
    };
    Service = {
      # wayvnc unlinks the socket on a clean exit; clear a stale one after a crash.
      ExecStartPre = "${pkgs.coreutils}/bin/rm -f %t/wayvnc.sock";
      ExecStart = "${pkgs.wayvnc}/bin/wayvnc --unix-socket %t/wayvnc.sock";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  home.packages = lib.optionals (!isDarkstar) [ darkstar-desktop ];
}
