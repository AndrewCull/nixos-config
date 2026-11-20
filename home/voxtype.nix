{ pkgs, ... }:

# Voxtype — local (whisper.cpp) voice-to-text that types at the cursor.
#
# Driven by a niri keybind (Mod+Shift+T → `voxtype record toggle`) rather than
# voxtype's built-in evdev hotkey, which would need andrew in the `input` group
# (any process could then read every keystroke). niri has no key-release binds,
# so this is press-to-start / press-to-stop rather than hold-to-talk.
#
# Config is left at upstream defaults (~/.config/voxtype/config.toml is not
# managed, so `voxtype setup model` can rewrite it): base.en model, output via
# wtype, clipboard fallback. First-time setup: `voxtype setup --download`.
{
  home.packages = [ pkgs.voxtype ];

  systemd.user.services.voxtype = {
    Unit = {
      Description = "Voxtype voice-to-text daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" "pipewire.service" "pipewire-pulse.service" ];
      Requisite = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.voxtype}/bin/voxtype -q daemon";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
