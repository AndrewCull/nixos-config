{ config, pkgs, ... }:

{
  networking.hostName = "darkstar";

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # ── CPU (Ryzen 9000 / Granite Ridge) ──────────────────
  hardware.cpu.amd.updateMicrocode = true;
  boot.kernelParams = [ "amd_pstate=active" ];

  # ── GPU (RX 9070 discrete + Granite Ridge iGPU) ───────
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.amdgpu.opencl.enable = true;

  # btrfs needs this in initrd for root mount
  boot.supportedFilesystems = [ "btrfs" ];

  # ── Steam / gaming ────────────────────────────────────
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
  };
  programs.gamemode.enable = true;

  # -- Secrets --
  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";

  sops.secrets.andrew-password.neededForUsers = true;

  # -- User --
  users.users.andrew = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" "networkmanager" ];
    hashedPasswordFile = config.sops.secrets.andrew-password.path;
  };
}
