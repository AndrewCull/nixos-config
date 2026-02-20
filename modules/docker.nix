{ config, pkgs, ... }:

{
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
    # use btrfs storage driver if on btrfs, otherwise overlay2
    # storageDriver = "btrfs";
  };

  # docker compose
  environment.systemPackages = with pkgs; [
    docker-compose
  ];
}
