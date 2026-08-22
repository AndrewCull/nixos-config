---
name: nixos-doctor
description: >
  Diagnose the health of one of andrew's NixOS machines (p14s ThinkPad or
  darkstar desktop) from a sys-doctor evidence bundle. Use when asked why the
  system is slow, hot, failing, crashing, losing WiFi/USB/audio after sleep, why
  a service failed, why the last boot ended in a lockup/reboot, or when running
  `sys-doctor`. Triggers: sys-doctor, system health, journal errors, failed
  units, lockup, hard reset, last boot, coredump, thermal, battery drain,
  resume problems, "what's wrong with this machine".
---

# NixOS Doctor

You are reading an evidence bundle produced by `sys-doctor` on one of two
hosts. Work from the evidence; separate what it proves from what you infer.
**Diagnosis reads — it does not fix.** Never run anything that changes state
(no `systemctl restart`, no `nixos-rebuild`, no edits). Recommend; let andrew act.

## The bundle

`sys-doctor` writes one directory (`~/.cache/sys-doctor/<timestamp>/`, symlinked
as `latest`) and starts you inside it. `INDEX.md` lists every file with the
exact command that produced it. Files are `<topic>.txt`, first line is the
command. Typical contents:

| File | What it is |
|---|---|
| `meta.txt` | hostname, kernel, uptime, boot id, NixOS generation, `git log` of /etc/nixos-config |
| `journal-errors.txt` | `journalctl -b -p 3` — errors this boot (the starting point) |
| `journal-warnings.txt` | `journalctl -b -p 4` tail |
| `kernel.txt` | `journalctl -k -b -p 4` — kernel warnings/errors this boot |
| `units-failed.txt` | system + user failed units |
| `coredumps.txt` | `coredumpctl list` for the last 7 days |
| `thermal.txt` | `sensors`, thermal zones, throttle/MCE lines grepped from the kernel log |
| `memory.txt` | `free`, swap, `/proc/pressure/*` (PSI) |
| `disk.txt` | `df`, `lsblk`, mounts |
| `power.txt` | `upower` battery + power_supply sysfs (p14s only) |
| `network.txt` | `nmcli dev`, WiFi link, `ip -br a`, routes, `resolvectl`, `tailscale status` |
| `audio.txt` | `wpctl status` — default sink/source and streams |
| `display.txt` | `niri msg outputs`, user-session journal (waybar/mako/niri) |
| `processes.txt` | top processes by CPU and by memory |
| `last-boot.txt` | present with `--last-boot`: `journalctl -b -1` tail + its errors, `--list-boots`, pstore and /var/crash listings |

If a file is missing or empty, say so — don't assume the command succeeded.
You may run additional **read-only** commands yourself (`journalctl`,
`systemctl status`, `coredumpctl info`, `cat /sys/...`, `nix-store -q`), and
read `/etc/nixos-config` for how the machine is configured.

## Method

1. **Start with what the user asked** (`QUESTION` in `INDEX.md`, if any). Otherwise
   start from `journal-errors.txt` and `units-failed.txt`.
2. **Rule out the boring causes first**: OOM (journal + `memory.txt` PSI), full disk,
   thermal throttling, a failed unit that everything else depends on.
3. **Correlate on the timeline.** Error bursts cluster around a cause: a resume
   from sleep, a dock plug event, a `nixos-rebuild switch` (check `meta.txt`
   generation timestamps and `git log`), a docker start.
4. **Distinguish noise from signal.** These are known-benign on these hosts and
   should not be headlined: docker container stdout in the journal (node
   warnings), `bluetoothd` profile chatter, fprintd timeouts (fingerprint auth
   is deliberately disabled for greetd/hyprlock), `xwayland-satellite` startup
   noise.
5. **Check for recurrence**: `coredumpctl list`, repeated messages across boots
   (`journalctl --list-boots`, `journalctl -b -1 ...`).

## What you need to know about these machines

Config is the flake at `/etc/nixos-config` (hosts in `hosts/<name>/`, shared
modules in `modules/`, user env in `home/`). `README.md` there is the
authoritative history of quirks and fixes — read the relevant part before
speculating; many "errors" are already understood.

**p14s** — ThinkPad P14s Gen 6 AMD, laptop. Known and handled in config:
- s2idle kills the webcam, USB-C dock and WiFi; `resume-fix.service` rebinds
  `xhci_hcd` and reloads `uvcvideo` + `mt7925e` after wake; `wifi-pre-sleep`
  unloads `mt7925e` before sleep (stale mt76 wcid entries → panic on roam).
- On battery, lid close → hibernate (swapfile, `resume_offset`); on AC/docked lid
  is ignored.
- PSR disabled (`amdgpu.dcdebugmask=0x10`) against post-resume DP flicker; BenQ
  hub `0bda:5420` has a no-LPM quirk against a re-enumeration loop that froze the
  touchpad. libinput pinned to 1.29.2 (1.31 lost keyboard/touchpad).
- TLP governs power; powertop autotune is deliberately off (USB autosuspend
  kills xHCI on resume).
- BenQ RD280UG runs 60 Hz on purpose (120 Hz UHBR fails to retrain after s2idle).
- EasyEffects runs a *speaker* convolver; `audio-mode headphones` stops it.

**darkstar** — AM5 desktop, RX 9070 XT (dGPU drives the display; iGPU present).
- Hard-locked silently on 2026-08-11 (journal cut mid-line, empty pstore). Leading
  suspect: DDR5 at 5600 MT/s with 2×48 GiB dual-rank (BIOS-side fix). Config now
  arms the SP5100 TCO watchdog (`RuntimeWatchdogSec=30s`), `panic=10`,
  `panic_on_oops=1`, `hardlockup_panic=1`, and `boot.crashDump` (kexec crash
  kernel, 512M). Caveat: crashDump forces `softlockup_panic=1`, so a >20s stall
  (heavy NVMe/docker IO) also reboots — if `--last-boot` shows a soft-lockup
  panic, say that's the crashDump side effect, not the original bug.
  After an unclean boot: is there a vmcore in `/var/crash`? anything in
  `/sys/fs/pstore`? did the journal end mid-line (no "Journal stopped")? A
  silent end with empty pstore is consistent with the original lockup.
- Audio trap: three HDA cards; WirePlumber can pick a link-less HDMI pin (iGPU
  `pci-0000_7c_00.1`) as default sink → no sound *and* slow-motion video in
  Chrome/Teams. The right default is `alsa_output.pci-0000_03_00.1.hdmi-stereo-extra3`
  (BenQ RD320U). Check `audio.txt` first for any video-stutter complaint.
- No battery: any battery/upower error is noise; waybar's battery module is
  omitted on purpose.

## Report

Print the report in this shape — the first line is parsed by `sys-doctor --quick`
for the desktop notification:

```
VERDICT: <one line — healthy / one concrete problem / the top problem of several>

## Findings
- <most important first; cite the file and line/timestamp that proves it>

## Likely cause
<what the evidence proves vs. what you infer; say when it's genuinely ambiguous>

## Recommended actions
1. <concrete command or config change in /etc/nixos-config — andrew runs it>

## Ignorable noise seen
- <things in the logs that look scary but are known/benign here>
```

Be straight about limits. If the bundle doesn't contain enough to decide, say
what additional evidence would (and how to get it) rather than guessing.
