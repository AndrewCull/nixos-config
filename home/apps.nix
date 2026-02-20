{ config, pkgs, ... }:

{
  # ── Browser ───────────────────────────────────────────
  programs.chromium = {
    enable = true;
    commandLineArgs = [
      "--ozone-platform-hint=auto"
      "--enable-features=VaapiVideoDecodeLinuxGL" # hw video decode on AMD
    ];
  };

  # ── Web App PWAs ──────────────────────────────────────
  xdg.desktopEntries = {
    superhuman = {
      name = "Superhuman";
      exec = "chromium --app=https://mail.superhuman.com";
      icon = "mail-client";
      type = "Application";
      categories = [ "Network" "Email" ];
    };

    google-meet = {
      name = "Google Meet";
      exec = "chromium --app=https://meet.google.com";
      icon = "video-display";
      type = "Application";
      categories = [ "Network" "VideoConference" ];
    };

    google-calendar = {
      name = "Google Calendar";
      exec = "chromium --app=https://calendar.google.com";
      icon = "calendar";
      type = "Application";
      categories = [ "Office" "Calendar" ];
    };

    # add more as needed:
    # slack = {
    #   name = "Slack";
    #   exec = "chromium --app=https://app.slack.com";
    #   icon = "slack";
    #   type = "Application";
    # };
  };

  # ── Dev tools ─────────────────────────────────────────
  home.packages = with pkgs; [
    # rust
    rustup

    # node
    nodejs_22
    nodePackages.pnpm

    # general dev
    just        # command runner (modern make)
    watchexec   # file watcher
    dive        # docker image explorer

    # networking / ops
    tailscale
    openssl
    ssh-copy-id

    # media / misc
    mpv         # video
    imv         # image viewer for wayland
    zathura     # pdf viewer, minimal
    pavucontrol # audio control gui
  ];
}
