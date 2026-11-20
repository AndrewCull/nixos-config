{ pkgs, osConfig, ... }:

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
#
# darkstar builds whisper.cpp with Vulkan so transcription runs on the
# RX 9070 XT (lets the larger models stay fast). The override is in
# cache.nixos.org, so no local compile. ggml-vulkan prefers discrete GPUs over the Granite Ridge
# iGPU by default; if it ever picks the iGPU, set whisper.gpu_device.
# p14s stays on CPU.
let
  voxtype =
    if osConfig.networking.hostName == "darkstar"
    then pkgs.voxtype.override { vulkanSupport = true; }
    else pkgs.voxtype;
in
{
  home.packages = [ voxtype ];

  systemd.user.services.voxtype = {
    Unit = {
      Description = "Voxtype voice-to-text daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" "pipewire.service" "pipewire-pulse.service" ];
      Requisite = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${voxtype}/bin/voxtype -q daemon";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
