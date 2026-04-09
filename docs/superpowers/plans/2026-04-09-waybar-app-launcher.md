# Waybar App Launcher Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Nix snowflake button to the far-left of waybar that opens rofi (drun mode) anchored to the top-left of the screen.

**Architecture:** Modify `home/niri.nix` — add a `custom/launcher` waybar module before `niri/workspaces`, append CSS for the button, and add rofi positioning config (`location`/`anchor`/`y-offset`) in `programs.rofi.extraConfig` so all rofi invocations appear top-left under the bar. Then update README.

**Tech Stack:** NixOS, home-manager, waybar, rofi.

---

### Task 1: Add custom/launcher waybar module

**Files:**
- Modify: `home/niri.nix` (waybar `mainBar` settings)

- [ ] **Step 1: Add `custom/launcher` to `modules-left`**

In `programs.waybar.settings.mainBar`, change:

```nix
modules-left = [ "niri/workspaces" ];
```

to:

```nix
modules-left = [ "custom/launcher" "niri/workspaces" ];
```

- [ ] **Step 2: Add the module definition**

Inside `mainBar` (alongside `clock`, `battery`, etc.), add:

```nix
"custom/launcher" = {
  format = "󱄅";
  tooltip = false;
  on-click = "rofi -show drun";
};
```

- [ ] **Step 3: Append CSS for the launcher button**

In `programs.waybar.style`, append inside the multiline string:

```css
#custom-launcher {
  font-size: 18px;
  margin: 0 8px 0 6px;
}
```

---

### Task 2: Anchor rofi to top-left globally

**Files:**
- Modify: `home/niri.nix` (`programs.rofi.extraConfig`)

- [ ] **Step 1: Add positioning keys to `extraConfig`**

Change:

```nix
extraConfig = {
  show-icons = true;
  display-drun = "";
  display-run = "";
  display-window = "";
};
```

to:

```nix
extraConfig = {
  show-icons = true;
  display-drun = "";
  display-run = "";
  display-window = "";
  location = 1;   # north-west
  anchor = 1;     # north-west
  x-offset = 0;
  y-offset = 28;  # matches waybar height so rofi sits just beneath it
};
```

---

### Task 3: Verify the build

- [ ] **Step 1: Dry-build**

Run: `nixos-rebuild dry-build --flake ~/nixos-config#p14s`
Expected: completes without errors.

- [ ] **Step 2: Apply**

Run: `rebuild` (fish alias for `sudo nixos-rebuild switch --flake ~/nixos-config#(hostname)`)
Expected: build succeeds, waybar restarts.

- [ ] **Step 3: Visual/functional check**

- Confirm the  snowflake appears at the far-left of waybar, left of the workspaces module.
- Click it → rofi appears in the top-left, just under the bar.
- Type to filter, arrow-navigate, Enter launches the app.
- Trigger rofi via the existing keybinding → also appears top-left.

---

### Task 4: Update README

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Mention the launcher button**

Add a line under the relevant waybar/niri section noting: "Waybar includes a Nix snowflake launcher button in the top-left that opens rofi (drun) anchored under the bar." Match the file's existing prose style.

---

### Task 5: Commit

- [ ] **Step 1: Stage and commit via GitButler**

Files changed: `home/niri.nix`, `README.md`.

Use GitButler to commit (direct `git commit` is blocked on this branch). Suggested message:

```
feat(niri): add waybar launcher button and anchor rofi top-left
```
