{ config, pkgs, lib, ... }:

{
  networking.hostName = "darkstar";

  # The RD320U runs at native 4K, niri scale 1.0 (pixel-perfect). Bump the
  # stylix font sizes ~25% over the shared defaults so text keeps the physical
  # size it had at the old scale 1.25. Scoped here so p14s is unaffected.
  # (waybar / rofi / mako / ghostty are bumped per-host in their home modules.)
  stylix.fonts.sizes = lib.mkForce {
    applications = 13;
    desktop = 13;
    popups = 20;
    terminal = 14;
  };
  # Cursor likewise scales with output scale. At scale 1.0 the old size (18 →
  # ~23px effective at scale 1.25) renders at a literal 23px, which is too small
  # on a 32" 4K panel — bump to 32 for a comfortable pointer.
  stylix.cursor.size = lib.mkForce 32;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # ── CPU (Ryzen 9000 / Granite Ridge) ──────────────────
  hardware.cpu.amd.updateMicrocode = true;
  boot.kernelParams = [ "amd_pstate=active" ];

  # ── Hang forensics ────────────────────────────────────
  # 2026-08-11: silent hard lockup at 07:11:56 after 6 days uptime. The journal
  # cut off mid-line, /sys/fs/pstore was empty, and there was no OOM, MCE, GPU
  # reset or thermal event — the CPU simply stopped without reaching the panic
  # handler. The box then sat dead for ~8h because nothing was configured to
  # notice. Leading suspect is the memory OC (2×48 GiB dual-rank at 5600 MT/s,
  # above AMD's qualified ceiling for 2R UDIMMs on AM5), which is a BIOS-side
  # fix. Everything below is so the *next* one leaves evidence and recovers.

  # Pet the SP5100 TCO watchdog that this board has always had and never used.
  # If userspace stops scheduling for 30s the hardware resets the machine,
  # instead of it sitting frozen until someone walks over to it.
  systemd.settings.Manager.RuntimeWatchdogSec = "30s";

  # Default is panic=0 — halt forever. Reboot 10s after a panic instead, and
  # treat an oops or a hard lockup as panic-worthy so they trigger the reboot
  # and the pstore dump rather than being logged to a journal that is, by
  # definition, no longer being written to disk.
  boot.kernel.sysctl = {
    "kernel.panic" = 10;
    "kernel.panic_on_oops" = 1;
    "kernel.hardlockup_panic" = 1;
  };

  # kexec crash kernel → a real /proc/vmcore. efi_pstore already captures the
  # ring buffer summary on its own; this is for when that isn't enough.
  # NOTE: this module also forces softlockup_panic=1 kernel-wide, so a CPU
  # stalled >20s (heavy NVMe/docker IO can do it) will panic and reboot too.
  # If that turns into spurious reboots, drop this option — the sysctls and
  # the watchdog above stand on their own.
  boot.crashDump.enable = true;
  boot.crashDump.reservedMemory = "512M";

  # One-keystroke memtest from the boot menu. Worth having, but note it will
  # NOT reproduce an idle-hours AM5 lockup — only uptime tests that.
  boot.loader.systemd-boot.memtest86.enable = true;

  # ── GPU (RX 9070 discrete + Granite Ridge iGPU) ───────
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
#  hardware.amdgpu.opencl.enable = true;

  # btrfs needs this in initrd for root mount
#  boot.supportedFilesystems = [ "btrfs" ];

  # ── Steam / gaming ────────────────────────────────────
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
  };
  programs.gamemode.enable = true;

  # mesa-demos → glxinfo (OpenGL renderer/version), vulkan-tools → vulkaninfo,
  # libva-utils → vainfo (confirm VA-API decode is live on the dGPU, not a
  # silent software-decode fallback).
  environment.systemPackages = with pkgs; [ openrgb mesa-demos vulkan-tools libva-utils ];

  # ── GPU RGB control ───────────────────────────────────
  # Profiles edited in the openrgb GUI land in ~/.config/OpenRGB; sync them
  # to /var/lib/OpenRGB on every rebuild so the service can load them.
  services.hardware.openrgb = {
    enable = true;
    motherboard = "amd";
    startupProfile = "Simple";
  };
  system.activationScripts.openrgbProfiles.text = ''
    if [ -d /home/andrew/.config/OpenRGB ]; then
      mkdir -p /var/lib/OpenRGB
      cp -f /home/andrew/.config/OpenRGB/*.orp /var/lib/OpenRGB/ 2>/dev/null || true
    fi
  '';

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
