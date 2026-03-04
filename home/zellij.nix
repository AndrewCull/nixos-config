{ config, pkgs, ... }:

{
  programs.zellij = {
    enable = true;

    settings = {
      theme = "gruvbox-dark";
      default_shell = "fish";
      pane_frames = false;
      simplified_ui = true;
      default_layout = "compact";

      keybinds.unbind = [ "Ctrl h" ]; # don't conflict with helix
    };
  };
}
