{ config, pkgs, inputs, ... }:

{
  imports = [
    ./niri.nix
    ./shell.nix
    ./editors.nix
    ./apps.nix
    ./theme.nix
  ];

  home.username = "andrew";
  home.homeDirectory = "/home/andrew";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  # ── SSH ──────────────────────────────────────────────
  programs.ssh = {
    enable = true;
    matchBlocks."github.com" = {
      identityFile = "~/.ssh/id_ed25519";
    };
  };

  # Decrypt SSH private key via agenix (uses host key for decryption)
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  age.secrets.id_ed25519 = {
    file = ../secrets/id_ed25519.age;
    path = "/home/andrew/.ssh/id_ed25519";
  };

  home.file.".ssh/id_ed25519.pub" = {
    source = ../secrets/id_ed25519.pub;
  };
}
