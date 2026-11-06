{
  config,
  pkgs,
  inputs,
  ...
}:

let
  # fabro — agent workflow factory CLI (not in nixpkgs). Pinned to the release in
  # ~/code/fabro-factory/VERSION; bump both together. Uses the static musl build:
  # the gnu build expects an FHS glibc that NixOS doesn't have.
  # A NIGHTLY since 2026-10-29: docs.fabro.sh tracks the nightlies, and v0.254 stable
  # lacked on_failure, `run --target` and the current Claude models.
  fabro = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "fabro";
    version = "0.400.0-nightly.0";
    src = pkgs.fetchurl {
      url = "https://github.com/fabro-sh/fabro/releases/download/v${version}/fabro-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-pH4SUsvNqh1ts8PXyu2eiywC8LPQjfT/8KZILRXeYDE=";
    };
    installPhase = ''
      install -Dm755 fabro $out/bin/fabro
    '';
  };
in
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

  # btop built with ROCm so it can read AMD GPU stats (util, VRAM, temp, power)
  programs.btop = {
    enable = true;
    package = pkgs.btop-rocm;
    settings = {
      shown_boxes = "cpu mem net proc gpu0";
      show_gpu_info = "On"; # GPU summary in the CPU box too
      gpu_mirror_graph = false;
      show_swap = true;
      show_disks = true;
      show_io_stat = true; # disk IO in the mem/disks box
      proc_tree = false;
    };
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
    fd # faster find
    jq # json
    gron # greppable json
    bottom # better top
    watchexec # file watcher
    tldr # simplified man pages
    httpie # simpler curl
    parallel # better xargs
    unzip
    p7zip
    tokei # code stats
    dust # disk usage
    arp-scan
    dig
    amdgpu_top # detailed AMD GPU monitor (per-process VRAM, clocks, power)
    tmux
    cargo
    rustc
    rustfmt
    clippy
    gnumake # make for Makefiles
    uv # python package/project manager (Astral)
    python3 # bare interpreter on PATH; uv manages project envs, tools still shell out to python3
    stripe-cli # stripe payments CLI (provides `stripe`)
    inputs.herdr.packages.${pkgs.system}.default # agent multiplexer TUI
    fabro # agent workflow factory CLI (fabro.sh), pinned musl release

    # yazi preview dependencies
    poppler-utils # PDF thumbnails
    ffmpegthumbnailer # video thumbnails
    mediainfo # media metadata
    imagemagick # SVG, HEIC, and other image formats
    unar # archive previews
    fontpreview # font file previews
    hexyl # hex viewer for binary files
    miller # CSV/TSV tabular preview
    glow # rendered markdown preview
  ];
}
