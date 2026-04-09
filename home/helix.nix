{ config, pkgs, ... }:

{
  programs.helix = {
    enable = true;
    defaultEditor = true;

    settings = {

      editor = {
        line-number = "relative";
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        lsp.display-messages = true;
        file-picker.hidden = false;
        indent-guides.render = true;
        statusline = {
          left = [ "mode" "spinner" "file-name" "file-modification-indicator" ];
          right = [ "diagnostics" "selections" "position" "file-encoding" "file-line-ending" "file-type" ];
        };
        text-width = 80;
        soft-wrap = {
          enable = true;
          wrap-at-text-width = true;
          wrap-indicator = "↪ ";
        };
      };

      keys.normal = {
        space.f = "file_picker";
        space.b = "buffer_picker";
        space.q = ":quit";
        space.w = ":write";
      };
    };

    languages = {
      language-server = {
        rust-analyzer = {
          command = "rust-analyzer";
          config.check.command = "clippy";
        };
        typescript-language-server = {
          command = "typescript-language-server";
          args = [ "--stdio" ];
        };
        nil = {
          command = "nil";
        };
        tailwindcss-ls = {
          command = "tailwindcss-language-server";
          args = [ "--stdio" ];
        };
      };

      language = [
        { name = "rust"; auto-format = true; }
        { name = "nix"; auto-format = true; formatter = { command = "nixfmt"; }; }
        { name = "typescript"; auto-format = true; }
        { name = "tsx"; auto-format = true; }
        { name = "javascript"; auto-format = true; }
        { name = "json"; auto-format = true; }
        { name = "toml"; auto-format = true; }
        { name = "markdown"; auto-format = true; soft-wrap.enable = true; }
      ];
    };

    extraPackages = with pkgs; [
      # LSP servers
      nil
      rust-analyzer
      nodePackages.typescript-language-server
      nodePackages.vscode-langservers-extracted
      tailwindcss-language-server

      # formatters
      nixfmt
      prettierd
    ];
  };
}
