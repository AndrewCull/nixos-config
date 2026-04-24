{ ... }:

{
  programs.cava = {
    enable = true;
    settings = {
      input = {
        method = "pipewire";
        source = "auto";
      };
    };
  };
}
