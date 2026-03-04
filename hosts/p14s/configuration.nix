{ config, pkgs, ... }:

{
  networking.hostName = "p14s";

  # ── AMD GPU ───────────────────────────────────────────
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  boot.kernelParams = [
    "amd_pstate=active"
  ];

  # ── Power management ──────────────────────────────────
  services.power-profiles-daemon.enable = true;

  # ── Fingerprint reader ────────────────────────────────
  services.fprintd.enable = true;

  # ── Lid/suspend behavior ──────────────────────────────
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "lock";
  };
}
