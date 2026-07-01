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
    matchBlocks."20.7.59.70" = {
      user = "bradmin";
      identityFile = "~/.ssh/p14s";
      identitiesOnly = true;
    };
    matchBlocks."darkstar" = {
      hostname = "darkstar";
      user = "andrew";
    };
  };

  services.ssh-agent.enable = true;
}
