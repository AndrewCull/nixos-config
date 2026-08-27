{ lib, osConfig, ... }:

# ── Speaker DSP (fixes quiet/thin built-in speakers) ──────
# The P14s Gen 6 AMD speakers are tuned in firmware by a Dolby Atmos
# convolver + loudness EQ that only runs under Windows. Linux plays the raw
# ALC257 output, so the speakers are audible but quiet and thin even with every
# mixer at 100%/0 dB. EasyEffects runs as a background service and reapplies
# that tuning, restoring loudness/body.
#
# We deliberately do NOT set services.easyeffects.preset here: `--load-preset`
# force-overwrites the live effect chain on every restart, which would clobber
# any tuning done in the GUI. Instead EasyEffects restores its own last-used
# chain (persisted in ~/.config/easyeffects/db). Current chain: autogain →
# convolver → stereo_tools. Once the tuning settles, snapshot the preset into
# confs/easyeffects/ and load it declaratively for reproducibility.
#
# The convolver's impulse response is the community P14s **G5** file (per the
# ArchWiki page for this model — no G6-specific one exists yet). Placed under
# $XDG_DATA_HOME (~/.local/share) so EasyEffects 8.x finds it in its irs picker.
#
# p14s ONLY. The convolver IR is a P14s laptop-speaker correction, so it is
# actively wrong anywhere else. darkstar is a desktop with no built-in speakers
# — it drives powered speakers on the rear line-out — so running this
# there just colours those with a laptop's frequency correction. Gating the
# service (rather than leaving it enabled and unused) also makes audio-mode's
# start/stop of EasyEffects a no-op on darkstar.
{
  services.easyeffects.enable = osConfig.networking.hostName == "p14s";

  xdg.dataFile."easyeffects/irs/P14s_G5_Dynamic.irs" =
    lib.mkIf (osConfig.networking.hostName == "p14s") {
      source = ../confs/easyeffects/P14s_G5_Dynamic.irs;
    };
}
