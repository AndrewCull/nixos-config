{ config, pkgs, ... }:

{
  networking.hostName = "p14s";

  # ── AMD GPU ───────────────────────────────────────────
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernelParams = [
    "amd_pstate=active"
    "thinkpad_acpi.mic_mute_led=1"
    "amd_pmc.enable_stb=1"        # proper AMD s2idle power management
  ];

  # Ensure AMD PMC is loaded for proper s2idle power states
  boot.kernelModules = [ "amd_pmc" ];

  # NPU firmware is incompatible — disable to avoid errors and save power
  boot.blacklistedKernelModules = [ "amdxdna" ];

  # ── Swap / hibernate ─────────────────────────────────
  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 96 * 1024;  # 96 GB — enough to hibernate 86 GB RAM
  }];

  # ── Power management ──────────────────────────────────
  powerManagement.enable = true;
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
      PLATFORM_PROFILE_ON_AC = "balanced";
    };
  };

  services.thermald.enable = true;

  powerManagement.powertop.enable = true;

  environment.systemPackages = with pkgs; [ powertop lm_sensors ];

  # ── Steam ────────────────────────────────────────
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
  };
  programs.gamemode.enable = true;

  # ── Fingerprint reader ────────────────────────────────
  services.fprintd.enable = true;

  # ── Lid/suspend behavior ──────────────────────────────
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "suspend";
    InhibitDelayMaxSec = 5;
  };

  # ── Suspend reliability ─────────────────────────────
  systemd.sleep.extraConfig = ''
    SuspendState=freeze
    HibernateDelaySec=3600
  '';

  # Reload MT7925 WiFi driver on resume to avoid broken WiFi after s2idle
  systemd.services."wifi-resume-fix" = {
    description = "Reload MT7925 WiFi module on resume";
    after = [ "suspend.target" "hibernate.target" "suspend-then-hibernate.target" ];
    wantedBy = [ "suspend.target" "hibernate.target" "suspend-then-hibernate.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.kmod}/bin/modprobe -r mt7925e && ${pkgs.coreutils}/bin/sleep 1 && ${pkgs.kmod}/bin/modprobe mt7925e";
    };
  };

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
