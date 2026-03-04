{ config, pkgs, ... }:

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
    tokei           # code stats
    dust            # disk usage
    arp-scan
    dig
  ];
}
