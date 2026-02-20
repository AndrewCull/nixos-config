# DO NOT EDIT — this is a placeholder.
# Replace with output of: nixos-generate-config --root /mnt
# Run this on the actual Dell XPS 13 during installation.

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # These will be auto-detected by nixos-generate-config:
  # boot.initrd.availableKernelModules = [ ... ];
  # boot.kernelModules = [ ... ];
  # fileSystems."/" = { ... };
  # fileSystems."/boot" = { ... };
  # swapDevices = [ ... ];

  # Placeholder — replace entire file after running nixos-generate-config
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
