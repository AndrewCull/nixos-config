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
    "thinkpad_acpi.mic_mute_led=0"
  ];

  # NPU firmware is incompatible — disable to avoid errors and save power
  boot.blacklistedKernelModules = [ "amdxdna" ];

  # ── Power management ──────────────────────────────────
  services.power-profiles-daemon.enable = false;

  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_BOOST_ON_BAT = 0;
      CPU_BOOST_ON_AC = 1;
      PLATFORM_PROFILE_ON_BAT = "low-power";
      PLATFORM_PROFILE_ON_AC = "performance";
    };
  };

  services.thermald.enable = true;

  powerManagement.powertop.enable = true;

  environment.systemPackages = [ pkgs.powertop ];

  # ── Fingerprint reader ────────────────────────────────
  services.fprintd.enable = true;

  # ── Lid/suspend behavior ──────────────────────────────
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "lock";
  };

  # -- User --
  users.users.andrew = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" "networkmanager" ];
    initialPassword = "changeme";
  };
}
