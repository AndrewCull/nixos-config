{ config, pkgs, lib, osConfig, ... }:

# ── AI / agent integration ────────────────────────────
# Keyboard-first, no new UI: scripts + keybinds + mako notifications that hand
# evidence to Claude Code. The *method* lives in repo skills (agents/skills/),
# symlinked into ~/.claude/skills so any agent session picks them up; the
# scripts here only gather facts and launch the agent.
#
#   sys-doctor            gather an evidence bundle, open claude in it (Mod+Shift+D)
#   sys-doctor --quick    headless claude -p, read-only tools → notification + report
#   sys-doctor --last-boot  previous boot (post-lockup forensics on darkstar)
#   sys-doctor-boot-check   user service: on a new boot, if the previous one ended
#                           uncleanly, offer "Diagnose with AI" via notification

let
  skillsDir = ../agents/skills;
  skillNames = lib.attrNames
    (lib.filterAttrs (_: t: t == "directory") (builtins.readDir skillsDir));

  # Tools the scripts shell out to. claude, ghostty, niri, tailscale, wpctl come
  # from the user PATH (claude is npm-global, not nixpkgs) — PATH is extended
  # below so the systemd user service sees them too.
  toolPath = lib.makeBinPath (with pkgs; [
    procps coreutils gnugrep gawk gnused findutils util-linux jq
    systemd            # journalctl, systemctl, coredumpctl, resolvectl
    lm_sensors upower networkmanager iproute2
    libnotify glow
  ]);

  sys-doctor = pkgs.writeShellScriptBin "sys-doctor" ''
    set -uo pipefail
    export PATH="${toolPath}:$HOME/.npm-global/bin:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:$PATH"

    usage() {
      cat <<'USAGE'
    sys-doctor [MODE] [--ask "question"]
      (default)     gather evidence, open Claude Code in the bundle (spawns ghostty if no tty)
      --quick       headless claude -p with read-only tools; VERDICT → notification, report in ~/.cache/sys-doctor/latest/report.md
      --last-boot   focus on the previous boot (journalctl -b -1) — post-lockup forensics
      --no-ai       gather only; print the bundle path
      --ask TEXT    a specific question to put at the top of the prompt
    USAGE
    }

    mode=interactive
    lastboot=0
    question=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --quick)     mode=quick ;;
        --no-ai)     mode=noai ;;
        --last-boot) lastboot=1 ;;
        --ask)       shift; question="''${1:-}" ;;
        -h|--help)   usage; exit 0 ;;
        *) echo "sys-doctor: unknown option $1" >&2; usage; exit 2 ;;
      esac
      shift
    done

    # Interactive claude needs a terminal. Launched from a keybind there is none,
    # so re-exec inside ghostty with the same arguments.
    if [ "$mode" = interactive ] && [ ! -t 1 ]; then
      args=()
      [ "$lastboot" = 1 ] && args+=(--last-boot)
      [ -n "$question" ] && args+=(--ask "$question")
      exec ghostty -e sys-doctor "''${args[@]}"
    fi

    root="''${XDG_CACHE_HOME:-$HOME/.cache}/sys-doctor"
    mkdir -p "$root"
    # Bundles older than two weeks are not evidence any more.
    find "$root" -mindepth 1 -maxdepth 1 -type d -mtime +14 -exec rm -rf {} + 2>/dev/null || true
    bundle="$root/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$bundle"
    ln -sfn "$bundle" "$root/latest"
    index="$bundle/INDEX.md"

    host=$(hostname)
    {
      echo "# sys-doctor bundle — $host — $(date -Is)"
      echo
      [ -n "$question" ] && { echo "QUESTION: $question"; echo; }
      [ "$lastboot" = 1 ] && { echo "FOCUS: previous boot (journalctl -b -1) — see last-boot.txt"; echo; }
      echo "Each file begins with the command that produced it. Read INDEX.md, then the files."
      echo
    } > "$index"

    # cap <file> <description> <command...>: run with a timeout, record in INDEX.
    cap() {
      local file="$1" desc="$2"; shift 2
      {
        echo "\$ $*"
        timeout 25 "$@" 2>&1 || echo "[exit $?]"
      } > "$bundle/$file.txt"
      echo "- \`$file.txt\` — $desc" >> "$index"
    }
    # capsh: same, for a pipeline given as one string.
    capsh() {
      local file="$1" desc="$2" cmd="$3"
      {
        echo "\$ $(echo "$cmd" | tr -s "[:space:]" " " | cut -c1-220)"
        timeout 25 bash -c "$cmd" 2>&1 || echo "[exit $?]"
      } > "$bundle/$file.txt"
      echo "- \`$file.txt\` — $desc" >> "$index"
    }

    echo "sys-doctor: gathering evidence → $bundle" >&2

    capsh meta "host, kernel, uptime, boot id, generations, config git log" '
      echo "hostname: $(hostname)"; echo "kernel:   $(uname -r)"; echo "uptime:   $(uptime | sed "s/.*up */up /;s/, *[0-9]* users*.*//")"
      echo "now:      $(date -Is)"; echo "boot_id:  $(cat /proc/sys/kernel/random/boot_id)"
      echo "nixos:    $(nixos-version 2>/dev/null)"; echo "system:   $(readlink /run/current-system)"
      echo; echo "## generations"; nixos-rebuild list-generations 2>/dev/null | tail -6
      echo; echo "## /etc/nixos-config"; git -C /etc/nixos-config log --oneline -15 2>/dev/null; git -C /etc/nixos-config status --short 2>/dev/null'
    # Priority-3 can be flooded (docker container stdout lands there on darkstar):
    # count by source first, then a bounded tail with container chatter removed,
    # then a short raw tail so nothing is hidden.
    capsh journal-errors  "errors this boot: counts by source, tail without container noise, raw tail" 'journalctl -b -p 3 --no-pager -q -o json | jq -r "._SYSTEMD_UNIT // .SYSLOG_IDENTIFIER // \"?\"" | sort | uniq -c | sort -rn | head -20; echo "--- last 400 (excluding docker container output)"; journalctl -b -p 3 --no-pager -q -o short-iso | grep -vE " [0-9a-f]{12}\[[0-9]+\]: " | tail -400; echo "--- last 60 raw"; journalctl -b -p 3 --no-pager -q -o short-iso | tail -60'
    capsh journal-warnings "last 300 warnings this boot"                'journalctl -b -p 4..4 --no-pager -q -o short-iso | tail -300'
    cap  kernel           "kernel warnings/errors this boot"            journalctl -k -b -p 4 --no-pager -q -o short-iso
    capsh units-failed    "failed system and user units"                'systemctl --failed --no-legend; echo "--- user"; systemctl --user --failed --no-legend'
    cap  coredumps        "core dumps, last 7 days"                     coredumpctl list --since=-7d --no-pager
    capsh thermal         "sensors, thermal zones, throttle/MCE lines"  'sensors 2>/dev/null; echo "--- thermal zones (m°C)"; for z in /sys/class/thermal/thermal_zone*; do [ -e "$z" ] || { echo "(none)"; break; }; printf "%s %s %s\n" "$(basename $z)" "$(cat $z/type)" "$(cat $z/temp)"; done; echo "--- kernel throttle/mce"; journalctl -k -b -q --no-pager | grep -iE "throttl|mce:|machine check|thermal|temperature above" | tail -40'
    capsh memory          "free, swap, PSI pressure"                    'free -h; echo; swapon --show; echo; for p in cpu memory io; do echo "pressure/$p: $(cat /proc/pressure/$p | tr "\n" " ")"; done'
    capsh disk            "df, lsblk, mounts"                           'df -h -x tmpfs -x devtmpfs -x efivarfs; echo; lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS; echo; findmnt -t btrfs,ext4,xfs,vfat -o TARGET,SOURCE,FSTYPE,OPTIONS'
    if ls /sys/class/power_supply/BAT* >/dev/null 2>&1; then
      capsh power "battery (upower + sysfs)" 'for b in $(upower -e 2>/dev/null | grep -i bat); do upower -i "$b"; done; echo "--- sysfs"; grep -H . /sys/class/power_supply/BAT*/{status,capacity,cycle_count,energy_full,energy_full_design,power_now} 2>/dev/null; echo "--- AC"; grep -H . /sys/class/power_supply/AC*/online 2>/dev/null'
    fi
    capsh network         "nmcli, wifi link, addresses, routes, DNS, tailscale" 'nmcli -t dev status; echo; nmcli -t -f IN-USE,SSID,SIGNAL,RATE,FREQ dev wifi 2>/dev/null | grep "^\*"; echo; ip -br a; echo; ip route; echo "--- resolvectl"; resolvectl status 2>/dev/null | head -40; echo "--- tailscale"; tailscale status 2>&1 | head -30'
    cap  audio            "wpctl status — default sink/source, streams"  wpctl status
    capsh display         "niri outputs, user-session journal (niri/waybar/mako)" 'niri msg outputs 2>&1; echo "--- niri windows: $(niri msg --json windows 2>/dev/null | jq length)"; echo "--- user journal (warnings+)"; journalctl --user -b -p 4 --no-pager -q -o short-iso | tail -120'
    capsh processes       "top processes by CPU and by memory"          'ps -eo pid,ppid,%cpu,%mem,rss,etime,comm --sort=-%cpu | head -20; echo; ps -eo pid,ppid,%cpu,%mem,rss,etime,comm --sort=-rss | head -20'
    if [ "$lastboot" = 1 ]; then
      capsh last-boot "previous boot: tail, errors, boots, pstore, /var/crash" 'journalctl --list-boots --no-pager -q | tail -5; echo "--- last 400 lines of previous boot"; journalctl -b -1 -n 400 --no-pager -q -o short-iso; echo "--- errors in previous boot"; journalctl -b -1 -p 3 --no-pager -q -o short-iso | tail -200; echo "--- pstore"; ls -la /sys/fs/pstore 2>&1; echo "--- /var/crash"; ls -la /var/crash 2>&1; echo "--- coredumps (all)"; coredumpctl list --no-pager 2>&1 | tail -20'
    fi

    prompt="Use the nixos-doctor skill to diagnose this machine ($host) from the sys-doctor evidence bundle in the current directory. Start with INDEX.md."
    [ "$lastboot" = 1 ] && prompt="$prompt Focus on why the PREVIOUS boot ended (last-boot.txt): clean shutdown, panic/watchdog reset, or silent lockup."
    [ -n "$question" ] && prompt="$prompt The specific question is: $question"

    case "$mode" in
      noai)
        echo "$bundle"
        ;;
      interactive)
        # Prompt must come BEFORE any variadic option (--add-dir <dirs...> would
        # swallow it as another directory and claude starts idle).
        cd "$bundle" && exec claude "$prompt"
        ;;
      quick)
        report="$bundle/report.md"
        cd "$bundle" || exit 1
        # Headless: dontAsk denies anything outside the allowlist without prompting
        # (the list is read-only on purpose — diagnosis never fixes), and
        # --max-turns plus the QUICK MODE instruction keep it to minutes, not a
        # full investigation. Interactive mode has no such limits.
        quickprompt="$prompt QUICK MODE: you have a small turn budget. Answer from the bundle files; run at most a few extra read-only commands to confirm the top finding, then write the report. Do not chase every container or secondary warning."
        # Triage, not forensics: Opus is plenty for a verdict and much faster
        # than the session default (Fable took ~4.5 min). Interactive mode keeps
        # the default model for the deep dives. Override: SYS_DOCTOR_MODEL=...
        if ! claude -p "$quickprompt" \
              --model "''${SYS_DOCTOR_MODEL:-claude-opus-5}" \
              --output-format text \
              --permission-mode dontAsk \
              --max-turns 25 \
              --allowedTools Read Glob Grep Skill \
                "Bash(journalctl *)" "Bash(systemctl status *)" "Bash(systemctl --user status *)" "Bash(systemctl --failed*)" "Bash(systemctl --user --failed*)" "Bash(systemctl list-*)" \
                "Bash(coredumpctl list*)" "Bash(coredumpctl info*)" \
                "Bash(cat /proc/*)" "Bash(cat /sys/*)" "Bash(ls *)" "Bash(df *)" "Bash(free *)" \
                "Bash(wpctl status*)" "Bash(wpctl inspect *)" "Bash(nmcli dev*)" "Bash(nmcli -t dev*)" "Bash(ip -br *)" "Bash(ip route*)" \
                "Bash(docker ps*)" "Bash(docker stats --no-stream*)" "Bash(docker logs *)" \
                "Bash(git -C /etc/nixos-config log*)" "Bash(git -C /etc/nixos-config diff*)" "Bash(nix-store -q *)" "Bash(nixos-rebuild list-generations*)" \
              > "$report" 2> "$bundle/claude.err"; then
          notify-send -u critical -a sys-doctor "sys-doctor failed" "$(tail -3 "$bundle/claude.err")"
          exit 1
        fi
        verdict=$(grep -m1 '^VERDICT:' "$report" | sed 's/^VERDICT:[[:space:]]*//')
        [ -z "$verdict" ] && verdict=$(head -c 200 "$report")
        if [ -t 1 ]; then
          glow -p "$report"
        else
          # -A waits for the click; "open" shows the full report in a terminal.
          if [ "$(notify-send -a sys-doctor -A open="Open report" "sys-doctor — $host" "$verdict")" = open ]; then
            exec ghostty -e glow -p "$report"
          fi
        fi
        ;;
    esac
  '';

  # Once per boot: if the previous boot did not end with a clean shutdown, offer
  # a diagnosis. "Clean" = journald logged its own stop or a shutdown target.
  sys-doctor-boot-check = pkgs.writeShellScriptBin "sys-doctor-boot-check" ''
    set -uo pipefail
    export PATH="${toolPath}:$HOME/.npm-global/bin:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:$PATH"
    state="''${XDG_STATE_HOME:-$HOME/.local/state}/sys-doctor"
    mkdir -p "$state"
    boot=$(cat /proc/sys/kernel/random/boot_id)
    [ "$(cat "$state/last-checked-boot" 2>/dev/null)" = "$boot" ] && exit 0
    echo "$boot" > "$state/last-checked-boot"

    # No previous boot in the journal → nothing to judge.
    journalctl -b -1 -n 1 -q --no-pager >/dev/null 2>&1 || exit 0
    if journalctl -b -1 -n 60 -o cat -q --no-pager 2>/dev/null \
         | grep -qE "Journal stopped|Reached target .*(Power-Off|Reboot|Halt|Shutdown)"; then
      exit 0
    fi

    ended=$(journalctl --list-boots -q --no-pager 2>/dev/null | awk '$1=="-1"{print $(NF-3), $(NF-2)}')
    # Wait for the notification daemon (mako is spawned by niri, may race us).
    for _ in $(seq 1 30); do
      busctl --user status org.freedesktop.Notifications >/dev/null 2>&1 && break
      sleep 1
    done
    choice=$(notify-send -u critical -a sys-doctor \
      -A diagnose="Diagnose with AI" -A ignore="Ignore" \
      "Previous boot ended uncleanly" \
      "Journal for the boot that ended $ended has no clean-shutdown record.")
    [ "$choice" = diagnose ] && exec ghostty -e sys-doctor --last-boot
    exit 0
  '';
in
{
  home.packages = [ sys-doctor sys-doctor-boot-check ];

  # agents/skills/<name> → ~/.claude/skills/<name>. Out-of-store symlinks so
  # skill edits in the checkout are live without a rebuild.
  home.file = lib.listToAttrs (map (name: lib.nameValuePair ".claude/skills/${name}" {
    source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos-config/agents/skills/${name}";
  }) skillNames);

  systemd.user.services.sys-doctor-boot-check = {
    Unit = {
      Description = "Offer an AI diagnosis when the previous boot ended uncleanly";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${sys-doctor-boot-check}/bin/sys-doctor-boot-check";
      # notify-send -A blocks until the user clicks or the toast is dismissed;
      # give up after 30 min rather than sit as a stray process.
      TimeoutStartSec = "30min";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
