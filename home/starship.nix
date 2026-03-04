{ config, ... }:

{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;

    settings = {
      format = "$character";
      right_format = "$git_branch$git_status$directory";
      add_newline = false;

      character = {
        success_symbol = "[›](bold green)";
        error_symbol = "[›](bold red)";
        format = "$symbol ";
      };

      directory = {
        style = "bold blue";
        truncation_length = 3;
        format = "[ $path ]($style)";
      };

      git_branch = {
        style = "dimmed white";
        format = "[$branch]($style) ";
      };

      git_status = {
        style = "dimmed white";
      };

      # disable noisy modules
      time.disabled = true;
      battery.disabled = true;
      gcloud.disabled = true;
      package.disabled = true;
      nodejs.disabled = true;
      rust.disabled = true;
      python.disabled = true;
      java.disabled = true;
      golang.disabled = true;
      line_break.disabled = true;
    };
  };
}
