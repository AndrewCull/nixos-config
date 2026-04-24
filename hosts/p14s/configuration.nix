{ config, pkgs, ... }:

{
  networking.hostName = "p14s";

  # ── AMD GPU ───────────────────────────────────────────
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.resumeDevice = "/dev/disk/by-uuid/e76b244b-31f9-47ea-9c5f-50b91a02a072";

  boot.kernelParams = [
    "amd_pstate=active"
    "thinkpad_acpi.mic_mute_led=1"
    "rtc_cmos.use_acpi_alarm=1"    # RTC wake for hibernate timer on AMD
    "resume=/dev/disk/by-uuid/e76b244b-31f9-47ea-9c5f-50b91a02a072"  # resume device for hibernate
    "resume_offset=9897984"        # physical offset of /var/lib/swapfile for hibernate
    "amdgpu.gpu_recovery=1"        # enable GPU reset on hang instead of requiring hard reboot
    "amdgpu.dcdebugmask=0x10"      # DC_DISABLE_PSR — fixes DP flicker/artifacts on external monitor after resume
  ];

  # Let video group control the mic-mute LED (avoids sudo in toggle script)
  systemd.tmpfiles.rules = [
    "z /sys/devices/platform/thinkpad_acpi/leds/platform::micmute/brightness 0664 root video -"
  ];

  # AMD PMC enables deep idle states during s2idle (do not pass enable_stb=1 — it crashes the driver)
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
      USB_AUTOSUSPEND = 0;
    };
  };

  services.thermald.enable = true;

  # powertop auto-tune disabled — its USB autosuspend kills the xHCI controller on resume
  # powertop is still available as a package for manual inspection
  powerManagement.powertop.enable = false;

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
  # MacBook-style: on AC or docked, lid close keeps the machine running
  # (so external monitor / clamshell mode work). On battery, go straight
  # to hibernate — this hardware only supports s2idle (no S3 deep sleep),
  # which drains battery fast, so skip s2idle entirely.
  services.logind.settings.Login = {
    HandleLidSwitch = "hibernate";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
    InhibitDelayMaxSec = 5;
  };

  # ── Suspend reliability ─────────────────────────────
  systemd.sleep.extraConfig = ''
    SuspendState=mem
    HibernateDelaySec=120
  '';

  # Reload MT7925 WiFi driver and rebind xHCI USB controllers on resume.
  # After s2idle the xHCI controllers that host the webcam and USB-C dock
  # (and with it the external DisplayPort monitor) come back in a broken
  # state — rebinding the PCI devices to the xhci_hcd driver recovers them.
  # Also nudges amdgpu to redetect DP connectors for the external monitor.
  systemd.services."resume-fix" = {
    description = "Fix WiFi, USB and external display after resume";
    after = [ "suspend.target" "hibernate.target" "suspend-then-hibernate.target" ];
    wantedBy = [ "suspend.target" "hibernate.target" "suspend-then-hibernate.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "resume-fix" ''
        # Rebind every xhci_hcd PCI device. unbind/bind is more reliable
        # than the sysfs `reset` attribute and recovers devices (camera,
        # dock, DP-alt) hanging off any of the controllers.
        for dev in /sys/bus/pci/drivers/xhci_hcd/0000:*; do
          [ -e "$dev" ] || continue
          id=$(basename "$dev")
          echo "$id" > /sys/bus/pci/drivers/xhci_hcd/unbind 2>/dev/null || true
          sleep 0.2
          echo "$id" > /sys/bus/pci/drivers/xhci_hcd/bind 2>/dev/null || true
        done

        # Reload UVC so the webcam re-enumerates cleanly
        ${pkgs.kmod}/bin/modprobe -r uvcvideo 2>/dev/null || true
        ${pkgs.kmod}/bin/modprobe uvcvideo 2>/dev/null || true

        # Kick amdgpu to redetect DP connectors (fixes "enabling link failed")
        for s in /sys/class/drm/card*-DP-*/status; do
          [ -e "$s" ] && echo detect > "$s" 2>/dev/null || true
        done

        # Reload WiFi driver
        ${pkgs.kmod}/bin/modprobe -r mt7925e
        sleep 2
        ${pkgs.kmod}/bin/modprobe mt7925e
      '';
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
