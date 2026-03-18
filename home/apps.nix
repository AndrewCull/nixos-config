{ config, pkgs, ... }:

{
  # ── Browser ─────────────────────────────────────────
  programs.google-chrome = {
    enable = true;
    commandLineArgs = [
      "--ozone-platform-hint=auto"
      "--enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoEncoder,VaapiIgnoreDriverChecks,VulkanFromANGLE,DefaultANGLEVulkan,Vulkan"
      "--disable-features=UseChromeOSDirectVideoDecoder"
      "--use-vulkan"
      "--use-angle=vulkan"
      "--enable-gpu-rasterization"
      "--enable-zero-copy"
      "--ignore-gpu-blocklist"
      "--canvas-oop-rasterization"
      "--disable-background-networking"
      "--disable-backgrounding-occluded-windows"
    ];
  };

  programs.firefox.enable = true;
  stylix.targets.firefox.profileNames = [ "default" ];

  # ── Web App PWAs ────────────────────────────────────
  xdg.desktopEntries = {
    claude = {
      name = "Claude";
      exec = "google-chrome-stable --app=https://claude.ai";
      icon = "web-browser";
      type = "Application";
      categories = [ "Network" ];
    };

    superhuman = {
      name = "Superhuman";
      exec = "google-chrome-stable --app=https://mail.superhuman.com";
      icon = "mail-client";
      type = "Application";
      categories = [ "Network" "Email" ];
    };

    google-meet = {
      name = "Google Meet";
      exec = "google-chrome-stable --app=https://meet.google.com";
      icon = "video-display";
      type = "Application";
      categories = [ "Network" "VideoConference" ];
    };

    google-calendar = {
      name = "Google Calendar";
      exec = "google-chrome-stable --app=https://calendar.google.com";
      icon = "calendar";
      type = "Application";
      categories = [ "Office" "Calendar" ];
    };

    netflix = {
      name = "Netflix";
      exec = "google-chrome-stable --app=https://netflix.com";
      icon = "video-display";
      type = "Application";
      categories = [ "Network" "AudioVideo" ];
    };
  };

  # ── Dev toolchains ──────────────────────────────────
  home.packages = with pkgs; [
    # rust — individual packages instead of rustup to avoid NixOS friction
    # (managed by nixpkgs unstable, so always near-latest stable)

    # node + claude code
    nodejs_22
    nodePackages.pnpm

    # databases
    postgresql  # psql client
    tableplus   # GUI database client

    # general dev
    just        # command runner (modern make)
    dive        # docker image explorer
    csvlens     # CSV viewer TUI
    pandoc      # document converter
    (texliveSmall.withPackages (ps: with ps; [
      collection-fontsrecommended
      collection-latexrecommended
      collection-mathscience
    ]))

    # networking / ops
    tailscale
    trayscale       # Tailscale GUI
    ngrok           # tunnel local servers for demos
    openssl
    ssh-copy-id
    rsync

    # media
    mpv         # video
    imv         # image viewer for wayland
    zathura     # pdf viewer
    xournalpp   # pdf annotation and signatures

    # gui apps
    graphite               # vector graphics editor
    system-config-printer  # printer management
    nautilus    # file manager
    zed-editor
    warp-terminal
    teams-for-linux
    zoom-us
    bitwarden-desktop
    bitwarden-cli
    obsidian
    organicmaps
    spotify
    slack
    libreoffice

    # terminal launcher for Nautilus "Open With"
    xdg-terminal-exec

    # recording
    obs-studio

    # fun hacker vibes
    cmatrix         # Matrix rain
    hollywood       # multi-pane hacker dashboard
    cbonsai         # terminal bonsai tree
    pipes-rs        # animated pipes screensaver
    genact          # fake activity generator
    fastfetch       # system info with ASCII art
    nms             # Sneakers movie decryption effect
    cool-retro-term # CRT terminal emulator
  ];
}
