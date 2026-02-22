{ config, pkgs, ... }:

{
  # ── Zsh ───────────────────────────────────────────────
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      # nix
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config#$(hostname)";
      update = "nix flake update ~/nixos-config";

      # general
      ll = "ls -la";
      gs = "git status";
      gp = "git push";
      gc = "git commit";
      gd = "git diff";

      # docker
      dc = "docker compose";
      dcu = "docker compose up -d";
      dcd = "docker compose down";
      dcl = "docker compose logs -f";
    };

    initContent = ''
      # direnv hook
      eval "$(direnv hook zsh)"
    '';
  };

  # ── Starship prompt ───────────────────────────────────
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$rust$nodejs$docker_context$character";

      character = {
        success_symbol = "[›](bold green)";
        error_symbol = "[›](bold red)";
      };

      directory = {
        style = "bold blue";
        truncation_length = 3;
      };

      git_branch = {
        style = "bold dimmed white";
        format = "[$branch]($style) ";
      };

      git_status = {
        style = "dimmed white";
      };

      rust = {
        format = "[$symbol$version]($style) ";
        style = "dimmed white";
      };

      nodejs = {
        format = "[$symbol$version]($style) ";
        style = "dimmed white";
      };

      docker_context = {
        format = "[$symbol$context]($style) ";
        style = "dimmed white";
      };
    };
  };

  # ── Direnv (per-project environments) ─────────────────
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true; # cached nix shells
  };

  # ── Git ───────────────────────────────────────────────
  programs.git = {
    enable = true;
    settings = {
      user.name = "Andrew"; # update with your full name
      user.email = ""; # update with your email
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };

  # ── CLI tools ─────────────────────────────────────────
  home.packages = with pkgs; [
    direnv
    eza       # modern ls
    bat       # modern cat
    zoxide    # smart cd
    fzf       # fuzzy finder
    jq        # json
    lazygit   # tui git
    tokei     # code stats
    dust      # disk usage
    httpie    # http client
  ];

  # ── Zoxide (smart cd) ────────────────────────────────
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}
