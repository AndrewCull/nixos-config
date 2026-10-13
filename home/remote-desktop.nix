{ config, pkgs, lib, osConfig, ... }:

let
  isDarkstar = osConfig.networking.hostName == "darkstar";

  # Viewer side (every host but darkstar): forward darkstar's wayvnc socket over
  # SSH to a local port and open it in wlvncc.
  darkstar-desktop = pkgs.writeShellScriptBin "darkstar-desktop" ''
    port=5901
    sock=/run/user/1000/wayvnc.sock
    ssh=${pkgs.openssh}/bin/ssh

    # First session: fail early with a clear message if wayvnc isn't serving.
    # ssh only notices a dead unix socket when the forwarded connection is
    # opened, and `ssh -f` backgrounds before the remote command runs, so
    # neither would surface it — wlvncc would just print "Failed to connect to
    # server". Ask systemd rather than testing the socket path: a stopped
    # wayvnc leaves its socket file behind. Same session powers the monitors
    # back on (swayidle turns them off when idle, which leaves nothing to
    # capture; an ssh session has no NIRI_SOCKET, hence the glob).
    $ssh darkstar "sh -c '
      systemctl --user is-active --quiet wayvnc \
        || { echo \"wayvnc.service is \$(systemctl --user is-active wayvnc)\" >&2; exit 1; }
      NIRI_SOCKET=\$(echo /run/user/1000/niri.*.sock) niri msg action power-on-monitors
    '" || {
      echo "darkstar-desktop: wayvnc is not running on darkstar." >&2
      echo "  Is a niri session logged in there, and has darkstar been rebuilt with the remote-desktop module?" >&2
      exit 1
    }

    # Second session: the tunnel. `sleep 10` holds it open just long enough for
    # wlvncc to connect — ssh stays alive until that forwarded connection
    # closes, so quitting the viewer tears the tunnel down.
    $ssh -f -o ExitOnForwardFailure=yes -L 127.0.0.1:$port:$sock darkstar 'sleep 10' \
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
