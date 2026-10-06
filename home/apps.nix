{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:

let
  # darkstar's RD320U runs native 4K at niri scale 1.0. Chrome (ozone/wayland)
  # follows the output scale, so at 1.0 its whole UI renders at native-pixel
  # size — tiny on a 4K panel. Force a 1.25 device scale factor to restore the
  # physical size it had at the old scale 1.25. Other hosts use real fractional
  # scaling, so Chrome already gets the right scale from Wayland — don't force.
  isDarkstar = osConfig.networking.hostName == "darkstar";

  # Nautilus thumbnails images through glycin, and nixpkgs builds it without
  # the (experimental) RAW loader. Rather than rebuild glycin-loaders and
  # everything that links it, pull the camera's embedded JPEG preview out with
  # exiftool — fast, and it matches what the camera showed on its screen.
  # The preview carries no orientation of its own, so apply the RAW's.
  raw-thumbnailer = pkgs.writeShellApplication {
    name = "raw-thumbnailer";
    runtimeInputs = with pkgs; [
      exiftool
      imagemagick
    ];
    text = ''
      in="$1" out="$2" size="$3"
      # Largest embedded image first; tag names vary by maker.
      for tag in JpgFromRaw PreviewImage OtherImage ThumbnailImage; do
        if exiftool -b -"$tag" "$in" > "$out.jpg" 2>/dev/null && [ -s "$out.jpg" ]; then
          break
        fi
      done
      [ -s "$out.jpg" ] || { rm -f "$out.jpg"; exit 1; }
      case "$(exiftool -n -s3 -Orientation "$in")" in
        2) orient=TopRight ;; 3) orient=BottomRight ;; 4) orient=BottomLeft ;;
        5) orient=LeftTop ;; 6) orient=RightTop ;; 7) orient=RightBottom ;;
        8) orient=LeftBottom ;; *) orient=TopLeft ;;
      esac
      magick "$out.jpg" -orient "$orient" -auto-orient -thumbnail "''${size}x''${size}" "png:$out"
      rm -f "$out.jpg"
    '';
  };

  rawMimeTypes = [
    "image/x-dcraw"
    "image/x-adobe-dng"
    "image/x-canon-cr2"
    "image/x-canon-cr3"
    "image/x-canon-crw"
    "image/x-fuji-raf"
    "image/x-kodak-dcr"
    "image/x-kodak-k25"
    "image/x-kodak-kdc"
    "image/x-minolta-mrw"
    "image/x-nikon-nef"
    "image/x-nikon-nrw"
    "image/x-olympus-orf"
    "image/x-panasonic-raw"
    "image/x-panasonic-raw2"
    "image/x-panasonic-rw"
    "image/x-panasonic-rw2"
    "image/x-pentax-pef"
    "image/x-sigma-x3f"
    "image/x-sony-arw"
    "image/x-sony-sr2"
    "image/x-sony-srf"
  ];
in
{
  # ── Browser ─────────────────────────────────────────
  programs.google-chrome = {
    enable = true;
    commandLineArgs = [
      "--ozone-platform=wayland"
      # GL-based VAAPI path — avoids the Vulkan/ANGLE combo that silently
      # falls back to software decode on AMD.
      "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder,AcceleratedVideoDecodeLinuxGL"
      "--disable-features=UseChromeOSDirectVideoDecoder"
      "--ignore-gpu-blocklist"
      "--enable-gpu-rasterization"
      "--enable-zero-copy"
      "--disable-background-networking"
      "--disable-backgrounding-occluded-windows"
    ]
    ++ lib.optional isDarkstar "--force-device-scale-factor=1.25";
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

  # ── Default applications ────────────────────────────
  # Home-manager owns ~/.config/mimeapps.list, so "set as default" from inside
  # an app won't stick — add the association here instead.
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "google-chrome.desktop";
      "x-scheme-handler/http" = "google-chrome.desktop";
      "x-scheme-handler/https" = "google-chrome.desktop";
      "x-scheme-handler/about" = "google-chrome.desktop";
      "x-scheme-handler/unknown" = "google-chrome.desktop";
      "x-scheme-handler/mailto" = "google-chrome.desktop";
      "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
      "x-scheme-handler/slack" = "slack.desktop";
      "x-scheme-handler/bitwarden" = "bitwarden.desktop";

      # Helix is a terminal app (Terminal=true); GIO hands it to
      # xdg-terminal-exec, which opens it in Ghostty (below).
      "text/plain" = "Helix.desktop";
      "text/markdown" = "Helix.desktop";
      "text/x-markdown" = "Helix.desktop";
    };
    # Helix.desktop doesn't declare markdown, so list it under "Open With" too.
    associations.added = {
      "text/markdown" = "Helix.desktop";
      "text/x-markdown" = "Helix.desktop";
    };
  };

  # Terminal for Terminal=true apps launched from Nautilus / "Open With".
  # Pinned, or xdg-terminal-exec may pick Warp or cool-retro-term.
  xdg.terminal-exec = {
    enable = true;
    settings.default = [ "com.mitchellh.ghostty.desktop" ];
  };

  # ── RAW thumbnails in Nautilus ──────────────────────
  xdg.dataFile."thumbnailers/raw.thumbnailer".text = ''
    [Thumbnailer Entry]
    TryExec=${lib.getExe raw-thumbnailer}
    Exec=${lib.getExe raw-thumbnailer} %i %o %s
    MimeType=${lib.concatStringsSep ";" rawMimeTypes};
  '';

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
      categories = [
        "Network"
        "Email"
      ];
    };

    google-meet = {
      name = "Google Meet";
      exec = "google-chrome-stable --app=https://meet.google.com";
      icon = "video-display";
      type = "Application";
      categories = [
        "Network"
        "VideoConference"
      ];
    };

    netflix = {
      name = "Netflix";
      exec = "google-chrome-stable --app=https://netflix.com";
      icon = "video-display";
      type = "Application";
      categories = [
        "Network"
        "AudioVideo"
      ];
    };

    display-pilot-2 = {
      name = "Display Pilot 2";
      exec = "/home/andrew/Applications/DisplayPilot2.AppImage";
      icon = "preferences-desktop-display";
      type = "Application";
      categories = [
        "Settings"
        "HardwareSettings"
      ];
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
      categories = [
        "Network"
        "Email"
      ];
      mimeType = [ "x-scheme-handler/mailto" ];
    };
  }
  // lib.optionalAttrs isDarkstar {
    x-plane-12 = {
      name = "X-Plane 12";
      exec = "xplane-run";
      icon = "applications-games";
      type = "Application";
      categories = [
        "Game"
        "Simulation"
      ];
    };
  };

  # ── Dev toolchains ──────────────────────────────────
  home.packages =
    with pkgs;
    let
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

      # X-Plane 12 ships its own CEF/Chromium and needs a full Linux desktop
      # runtime. Build a comprehensive FHS env (steam-run's helper closure
      # turned out to be too thin — only ~13 surface packages).
      xplane-run = pkgs.buildFHSEnv {
        name = "xplane-run";
        targetPkgs =
          p: with p; [
            # base
            bashInteractive
            coreutils
            glibc
            zlib
            # graphics
            libGL
            libglvnd
            vulkan-loader
            libgbm
            mesa
            libdrm
            # X11
            libx11
            libxext
            libxi
            libxcursor
            libxrandr
            libxxf86vm
            libxinerama
            libxfixes
            libxrender
            libxscrnsaver
            libxcomposite
            libxdamage
            libxtst
            libxcb
            libxshmfence
            libxt
            libice
            libsm
            libxkbcommon
            # audio
            alsa-lib
            libpulseaudio
            pipewire
            # CEF / Chromium runtime
            nss
            nspr
            gtk3
            glib
            gobject-introspection
            pango
            cairo
            atk
            at-spi2-atk
            at-spi2-core
            cups
            dbus
            expat
            fontconfig
            freetype
            harfbuzz
            gdk-pixbuf
            libnotify
            libsecret
            libxslt
            sqlite
            icu
            # X-Plane Identity Login uses WebKitGTK 4.1, which needs
            # glib-networking to provide GIO's TLS backend — without it,
            # the in-app browser logs "TLS support is not available" and
            # license activation fails.
            webkitgtk_4_1
            glib-networking
            # gamemode (libgamemodeauto.so + gamemoderun)
            gamemode
            # misc
            udev
            libuuid
            libcap
            stdenv.cc.cc.lib
            curl
            openssl
          ];
        runScript = ''
          bash -c '
            cd "/home/andrew/Games/X-Plane 12"
            # GLib was built with its GIO module dir pinned into the Nix store,
            # so glib-networking (installed inside the FHS at /usr/lib64/gio/modules)
            # is invisible without an explicit hint. Without it WebKitGTK has no
            # TLS backend and the login flow reports "TLS support is not available".
            export GIO_EXTRA_MODULES=/usr/lib64/gio/modules
            # Force RADV (open-source Mesa Vulkan driver) on AMD
            export AMD_VULKAN_ICD=RADV
            # gpl = Graphics Pipeline Library, reduces shader compile stutter
            export RADV_PERFTEST=gpl
            # Mesa: cache shaders so cold-start stutter only happens once
            export MESA_SHADER_CACHE_DIR="$HOME/.cache/mesa_shader_cache"
            mkdir -p "$MESA_SHADER_CACHE_DIR"
            exec gamemoderun ./X-Plane-x86_64 "$@"
          '
        '';
      };
    in
    [
      # rust — individual packages instead of rustup to avoid NixOS friction
      # (managed by nixpkgs unstable, so always near-latest stable)

      # node + claude code
      nodejs_22
      pnpm

      # Fast-tracked ahead of nixpkgs. The package takes an overridable
      # `manifest` argument and derives both its version and the binary's
      # checksum from it, so pinning our own copy is enough to move it — no
      # hash to recompute. confs/claude-code-manifest.json is refreshed daily
      # by .github/workflows/claude-code-bump.yml, which keeps Claude Code on
      # the day's release without dragging the kernel along on the same bump.
      (claude-code.override {
        manifest = lib.importJSON ../confs/claude-code-manifest.json;
      })

      # databases
      postgresql # psql client
      tableplus # GUI database client

      # general dev
      just # command runner (modern make)
      dive # docker image explorer
      csvlens # CSV viewer TUI
      pandoc # document converter
      (texliveSmall.withPackages (
        ps: with ps; [
          collection-fontsrecommended
          collection-latexrecommended
          collection-mathscience
        ]
      ))

      # cloud / deploy
      render-cli # Render.com CLI
      wrangler # Cloudflare Workers/Pages/R2 CLI

      # networking / ops
      tailscale
      trayscale # Tailscale GUI
      ngrok # tunnel local servers for demos
      openssl
      ssh-copy-id
      rsync
      rclone # sync to/from cloud storage (R2, S3, Drive, ...)

      # media
      mpv # video
      imv # image viewer for wayland
      zathura # pdf viewer
      xournalpp # pdf annotation and signatures

      # gui apps
      graphite # vector graphics editor
      system-config-printer # printer management
      nautilus # file manager
      zed-editor
      warp-terminal
      teams-for-linux
      zoom-us
      protonmail-desktop
      bitwarden-desktop
      bitwarden-cli
      morgen # calendar app
      obsidian
      basalt # Obsidian notes TUI
      organicmaps
      spotify
      slack
      libreoffice
      prusa-slicer
      inkscape
      gimp
      darktable # RAW photo viewer / developer

      # recording
      obs-studio

      # local CLIs (symlinked from source builds)
      (pkgs.runCommand "os-cli" { } ''
        mkdir -p $out/bin
        ln -s /home/andrew/code/agema_os/os-cli/target/release/os $out/bin/os
      '')

      # fun hacker vibes
      cmatrix # Matrix rain
      hollywood # multi-pane hacker dashboard
      cbonsai # terminal bonsai tree
      pipes-rs # animated pipes screensaver
      genact # fake activity generator
      fastfetch # system info with ASCII art
      nms # Sneakers movie decryption effect
      cool-retro-term # CRT terminal emulator
    ]
    # gaming — darkstar only; p14s stays lean
    ++ lib.optionals isDarkstar [
      steam-run # FHS env for running non-Nix binaries (X-Plane installer, etc.)
      xplane-run
    ];
}
