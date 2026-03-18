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

  home.packages = [
    pkgs.gitbutler
    (pkgs.stdenv.mkDerivation {
      pname = "but";
      version = "0.19.5";
      src = pkgs.fetchurl {
        url = "https://releases.gitbutler.com/releases/release/0.19.5-2897/linux/x86_64/but";
        hash = "sha256-qQAjL6ImIvCKGXELWmcAMBs0J3QPNP+0UsXUElpO1eg=";
      };
      nativeBuildInputs = [ pkgs.autoPatchelfHook ];
      buildInputs = [ pkgs.dbus pkgs.zlib pkgs.stdenv.cc.cc.lib ];
      dontUnpack = true;
      installPhase = ''
        install -Dm755 $src $out/bin/but
      '';
    })
  ];
}
