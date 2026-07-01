# ── Logitech MX Keys ───────────────────────────────────────
#
# Keyd remap for the Logitech MX Keys (Bluetooth, 046d:b35b).
#
# This keyboard's bottom-left modifiers report as:
#   Start key → leftmeta (already Super)
#   Cmd key   → leftalt
#
# We make the Cmd key act as Super so it works like a Mac
# Command key for niri's Mod bindings. The Start key is left
# untouched (so Super ends up on both keys).
#
# Trade-off: with Cmd → Super there is no LEFT Alt anymore;
# only the right-hand Alt remains. If you'd rather keep a left
# Alt, switch to a SWAP instead by uncommenting the swap block
# below and removing the single-line remap.
#
# keyd configs are matched per device id, so this block is
# inert on any machine where the MX Keys isn't connected and
# never interferes with the HHKB (see modules/hhkb.nix).

{ config, pkgs, lib, ... }:

{
  services.keyd.keyboards.mxkeys = {
    ids = [ "046d:b35b" ];
    settings = {
      main = {
        # Cmd (reports as leftalt) → Super
        leftalt = "leftmeta";

        # ── Swap alternative (keeps a left Alt) ──
        # Comment out the line above and uncomment these two to
        # make Cmd = Super and Start = Alt instead:
        # leftalt = "leftmeta";
        # leftmeta = "leftalt";
      };
    };
  };
}
