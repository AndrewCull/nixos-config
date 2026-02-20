{ config, pkgs, ... }:

{
  networking.hostName = "p14s";

  # ── AMD GPU ───────────────────────────────────────────
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # for xplane/gaming
  };

  # AMD-specific kernel params
  boot.kernelParams = [
    "amd_pstate=active" # modern AMD power management
  ];

  # ── Power management (laptop) ─────────────────────────
  services.thermald.enable = false; # intel only, not needed
  services.power-profiles-daemon.enable = true;

  # TLP for fine-grained battery optimization
  # (disable power-profiles-daemon if using TLP instead)
  # services.tlp = {
  #   enable = true;
  #   settings = {
  #     CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
  #     CPU_SCALING_GOVERNOR_ON_AC = "performance";
  #   };
  # };

  # ── Bluetooth ─────────────────────────────────────────
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # ── Disk encryption note ──────────────────────────────
  # LUKS is configured during install via:
  #   cryptsetup luksFormat /dev/nvme0n1p2
  #   cryptsetup open /dev/nvme0n1p2 cryptroot
  # Then reference in hardware-configuration.nix:
  #   boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/YOUR-UUID";

  # ── Lid/suspend behavior ──────────────────────────────
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "lock";
  };
}
