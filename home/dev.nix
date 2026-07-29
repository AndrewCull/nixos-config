{ config, pkgs, inputs, ... }:

{
  # ── CLI tools with home-manager integration ─────────
  programs.bat.enable = true;

  programs.eza = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.ripgrep.enable = true;

  programs.pay-respects = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "";
  };

  home.sessionVariables = {
    # Claude Code's mouse tracking fights zellij's mouse_mode — clicks paste
    # the clipboard. Disable it; keyboard input is unaffected.
    CLAUDE_CODE_DISABLE_MOUSE = "1";
  };

  # ── Packages ────────────────────────────────────────
  home.packages = with pkgs; [
    fd              # faster find
    jq              # json
    gron            # greppable json
    bottom          # better top
    watchexec       # file watcher
    tldr            # simplified man pages
    httpie          # simpler curl
    parallel        # better xargs
    unzip
    p7zip
    tokei           # code stats
    dust            # disk usage
    arp-scan
    dig
    btop
    tmux
    cargo
    rustc
    rustfmt
    clippy
    gnumake         # make for Makefiles
    uv              # python package/project manager (Astral)
    stripe-cli      # stripe payments CLI (provides `stripe`)
    inputs.herdr.packages.${pkgs.system}.default  # agent multiplexer TUI

    # yazi preview dependencies
    poppler-utils       # PDF thumbnails
    ffmpegthumbnailer   # video thumbnails
    mediainfo           # media metadata
    imagemagick         # SVG, HEIC, and other image formats
    unar                # archive previews
    fontpreview         # font file previews
    hexyl               # hex viewer for binary files
    miller              # CSV/TSV tabular preview
    glow                # rendered markdown preview
  ];
}
