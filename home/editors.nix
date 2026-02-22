{ config, pkgs, inputs, ... }:

{
  # ── Neovim (LazyVim) ──────────────────────────────────
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # LazyVim manages its own plugins, so we just need
    # the dependencies available on the system
    extraPackages = with pkgs; [
      # LSP servers
      lua-language-server
      nil                  # nix LSP
      rust-analyzer
      nodePackages.typescript-language-server
      nodePackages.vscode-langservers-extracted # html/css/json
      tailwindcss-language-server

      # formatters / linters
      stylua
      nixfmt
      prettierd
      eslint_d

      # misc tools lazyvim expects
      gcc
      gnumake
      tree-sitter
      lazygit
    ];
  };

  # LazyVim config lives in ~/.config/nvim
  # Clone your existing config or start fresh:
  #   git clone https://github.com/LazyVim/starter ~/.config/nvim

  # ── Zed + Ghostty ─────────────────────────────────────
  home.packages = (with pkgs; [
    zed-editor
  ]) ++ [
    inputs.ghostty.packages.x86_64-linux.default
  ];

  # Ghostty config lives at ~/.config/ghostty/config
  xdg.configFile."ghostty/config".text = ''
    font-family = JetBrains Mono
    font-size = 11

    # no rounded corners, sharp aesthetic
    window-decoration = false
    window-padding-x = 8
    window-padding-y = 8

    # let stylix handle colors, or set manually:
    # background = #1a1a2e
    # foreground = #c8c8d0

    cursor-style = bar
    cursor-style-blink = false

    shell-integration = zsh
    confirm-close-surface = false
  '';
}
