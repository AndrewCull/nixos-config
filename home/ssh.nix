{ config, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."github.com" = {
      identityFile = "~/.ssh/github";
      identitiesOnly = true;
    };
    matchBlocks."*.render.com render.com" = {
      identityFile = "~/.ssh/render";
      identitiesOnly = true;
    };
  };

  services.ssh-agent.enable = true;
}
