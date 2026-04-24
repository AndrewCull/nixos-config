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

  programs.firefox = {
    enable = true;
    profiles.default = {
      settings = {
        # ── Hardware video acceleration (AMD VA-API) ──
        "media.ffmpeg.vaapi.enabled" = true;
        "media.hardware-video-decoding.enabled" = true;
        "media.hardware-video-decoding.force-enabled" = true;
        "gfx.webrender.all" = true;

        # ── WebGL / GPU compositing ──────────────────
        "webgl.force-enabled" = true;
        "layers.acceleration.force-enabled" = true;
        "gfx.canvas.accelerated" = true;

        # ── Wayland native ───────────────────────────
        "widget.use-xdg-desktop-portal.file-picker" = 1;

        # ── WebRTC (video calls) optimizations ───────
        "media.navigator.mediadatadecoder_vpx_enabled" = true;
        "media.webrtc.hw.h264.enabled" = true;
        "media.peerconnection.video.h264_enabled" = true;
      };
    };
  };
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

    netflix = {
      name = "Netflix";
      exec = "google-chrome-stable --app=https://netflix.com";
      icon = "video-display";
      type = "Application";
      categories = [ "Network" "AudioVideo" ];
    };

    display-pilot-2 = {
      name = "Display Pilot 2";
      exec = "/home/andrew/Applications/DisplayPilot2.AppImage";
      icon = "preferences-desktop-display";
      type = "Application";
      categories = [ "Settings" "HardwareSettings" ];
    };

    # Override the package's entry — on niri/Wayland the app only renders
    # with --ozone-platform=x11 (via XWayland).
    proton-mail = {
      name = "Proton Mail";
      genericName = "Proton Mail";
      exec = "proton-mail --ozone-platform=x11 %U";
      icon = "proton-mail";
      type = "Application";
      startupNotify = true;
      categories = [ "Network" "Email" ];
      mimeType = [ "x-scheme-handler/mailto" ];
    };
  };

  # ── Dev toolchains ──────────────────────────────────
  home.packages = with pkgs; let
    render-cli = stdenv.mkDerivation rec {
      pname = "render-cli";
      version = "2.14.0";
      src = fetchzip {
        url = "https://github.com/render-oss/cli/releases/download/v${version}/cli_${version}_linux_amd64.zip";
        hash = "sha256-gow0w0ioPG/I2RQwj5RRJQqCDoGSHAzxIaIliBApygw=";
        stripRoot = false;
      };
      nativeBuildInputs = [ autoPatchelfHook ];
      installPhase = ''
        install -Dm755 cli_v${version} $out/bin/render
      '';
    };
  in [
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

    # cloud / deploy
    render-cli      # Render.com CLI

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
    protonmail-desktop
    bitwarden-desktop
    bitwarden-cli
    morgen          # calendar app
    obsidian
    basalt          # Obsidian notes TUI
    organicmaps
    spotify
    slack
    libreoffice
    prusa-slicer
    inkscape
    gimp

    # terminal launcher for Nautilus "Open With"
    xdg-terminal-exec

    # recording
    obs-studio

    # local CLIs (symlinked from source builds)
    (pkgs.runCommand "os-cli" {} ''
      mkdir -p $out/bin
      ln -s /home/andrew/code/agema_os/os-cli/target/release/os $out/bin/os
    '')

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
