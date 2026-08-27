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

    # Floating panes for the things that answer a question and get out of the way. zellij
    # has a plugin system, but a file browser, a git UI and a status board are all just TUIs,
    # and a floating pane running one is simpler than a plugin and survives the tool changing.
    # Raw KDL: home-manager's settings attrset cannot express zellij keybinds, whose action
    # names are bare KDL nodes rather than strings.
    extraConfig = ''
      keybinds {
        shared_except "locked" {
          // file viewer — yazi, with the preview stack from home/dev.nix
          bind "Ctrl y" { Run "yazi" { floating true; close_on_exit true; }; }
          // git
          bind "Ctrl g" { Run "lazygit" { floating true; close_on_exit true; }; }
          // where the work is: worktrees in flight, what is ready, what needs a decision
          bind "Ctrl b" {
            Run "bash" "-lc" "~/code/process/bin/board.sh; echo; read -n1 -r -p '[any key]'" {
              floating true; close_on_exit true;
            };
          }
        }
      }
    '';
  };
}
