{ config, pkgs, ... }:

{
  # ── Browser ─────────────────────────────────────────
  programs.chromium = {
    enable = true;
    commandLineArgs = [
      "--ozone-platform-hint=auto"
      "--enable-features=VaapiVideoDecodeLinuxGL"
    ];
  };

  programs.firefox.enable = true;
  stylix.targets.firefox.profileNames = [ "default" ];

  # ── Web App PWAs ────────────────────────────────────
  xdg.desktopEntries = {
    claude = {
      name = "Claude";
      exec = "chromium --app=https://claude.ai";
      icon = "web-browser";
      type = "Application";
      categories = [ "Network" ];
    };

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
  };

  # ── Dev toolchains ──────────────────────────────────
  home.packages = with pkgs; [
    # rust
    rustup

    # node + claude code
    nodejs_22
    nodePackages.pnpm

    # general dev
    just        # command runner (modern make)
    dive        # docker image explorer

    # networking / ops
    tailscale
    openssl
    ssh-copy-id

    # media
    mpv         # video
    imv         # image viewer for wayland
    zathura     # pdf viewer

    # gui apps
    nautilus    # file manager
    zed-editor
    warp-terminal
    teams-for-linux
    zoom-us
    bitwarden-desktop
    obsidian
    spotify

    # recording
    obs-studio
  ];
}
