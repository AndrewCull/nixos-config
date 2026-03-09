# ── HHKB Professional Hybrid ───────────────────────────────
#
# Keyd-based configuration for the HHKB Pro Hybrid on Linux.
# Provides a software media/nav layer since the hardware Fn
# key is invisible to the OS.
#
# ── Recommended DIP switch settings (HHK mode) ────────────
#   SW1 OFF  SW2 OFF  →  HHK mode (Unix layout, Ctrl at CapsLock)
#   SW3 ON             →  Delete key sends Backspace
#   SW4 OFF            →  Left ◇ = Super (for WM bindings)
#   SW5 OFF            →  Default Alt/Meta positions
#   SW6 ON             →  Disable power saving (better BT reconnect)
#
# ── Bluetooth pairing ─────────────────────────────────────
#   Fn+Q             → enter pairing mode
#   Fn+Ctrl+1-4      → switch BT profile
#   Fn+Ctrl+0        → switch to USB
#
# ── Hardware Fn layer (always available) ──────────────────
#   Fn+1-0/-/=       → F1–F12
#   Fn+[  /  ;  '    → Up  Left  Down  Right  (actually: [ → Up, ; → Left, ' → Right, / → Down)
#   Fn+K  ,  L  .    → Home  End  PgUp  PgDn
#   Fn+`             → Delete (when SW3=ON and Delete=Backspace)
#   Fn+Tab           → Caps Lock
#   Fn+P             → Print Screen
#
# ── Software layer (this config) ──────────────────────────
#   Hold Right Alt + key:
#     a → Volume Down       s → Volume Up       d → Mute
#     f → Mic Mute
#     q → Brightness Down   w → Brightness Up
#     e → Screenshot (Print Screen)
#     h → Left              j → Down             k → Up        l → Right
#     u → Home              i → End
#     y → Page Up           n → Page Down
#     m → Media Play/Pause
#     , → Media Previous    . → Media Next

{ config, pkgs, lib, ... }:

{
  services.keyd = {
    enable = true;
    keyboards = {
      hhkb = {
        ids = [ "04fe:0021" ];
        settings = {
          main = {
            muhenkan = "leftmeta";
            rightalt = "layer(hhkb)";
          };

          # Software media/nav layer on Right Alt
          hhkb = {
            # Volume
            a = "volumedown";
            s = "volumeup";
            d = "mute";
            f = "micmute";

            # Brightness
            q = "brightnessdown";
            w = "brightnessup";

            # Screenshot
            e = "sysrq";

            # Arrow keys (vim-style)
            h = "left";
            j = "down";
            k = "up";
            l = "right";

            # Navigation
            u = "home";
            i = "end";
            y = "pageup";
            n = "pagedown";

            # Media playback
            m = "playpause";
            "," = "previoussong";
            "." = "nextsong";
          };
        };
      };
    };
  };
}
