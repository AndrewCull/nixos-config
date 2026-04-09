{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user.name = "Andrew";
      user.email = "andrew@agemalabs.com";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.editor = "hx";
    };
  };

  programs.gh = {
    enable = true;
    settings = {
      editor = "hx";
      git_protocol = "ssh";
    };
  };

  programs.delta = {
    enable = true;
    options = {
      navigate = true;
      side-by-side = true;
      line-numbers = true;
      syntax-theme = "gruvbox-dark";
    };
  };

  programs.lazygit.enable = true;
}
