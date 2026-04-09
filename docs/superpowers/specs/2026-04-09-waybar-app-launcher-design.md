# Waybar App Launcher Button

## Goal

Add a clickable Nix snowflake icon to the far-left of the waybar that opens a rofi drun menu for launching applications via keyboard or mouse.

## Context

- Waybar and rofi are already configured in `home/niri.nix`.
- Rofi has `show-icons = true` and a `display-drun` glyph set.
- `modules-left` currently contains only `niri/workspaces`.

## Design

Add a `custom/launcher` waybar module, placed before `niri/workspaces` in `modules-left`.

### Module config (in `home/niri.nix`, `programs.waybar.settings.mainBar`)

```nix
modules-left = [ "custom/launcher" "niri/workspaces" ];

"custom/launcher" = {
  format = "󱄅";
  tooltip = false;
  on-click = "rofi -show drun";
};
```

### Rofi positioning (global)

Anchor the rofi window to the top-left of the screen so it visually drops down from the launcher button. Add to `programs.rofi.extraConfig`:

```nix
location = 1;   # north-west
anchor = 1;     # north-west
x-offset = 0;
y-offset = 28;  # waybar height, so rofi sits just beneath it
```

This applies to all rofi invocations (waybar button and existing keybindings).

### Style (append to `programs.waybar.style`)

```css
#custom-launcher {
  font-size: 18px;
  margin: 0 8px 0 6px;
}
```

## Behavior

- Clicking the snowflake launches `rofi -show drun`.
- Rofi lists desktop applications; user filters by typing, navigates with arrows or mouse, launches with Enter or click.
- No keybinding added (existing launcher keybindings unaffected).

## Non-goals

- No new packages.
- No keybinding changes.
- No custom rofi theme work.

## Verification

- `nixos-rebuild dry-build --flake ~/nixos-config#p14s` succeeds.
- After `rebuild`, waybar shows the snowflake at the far left.
- Clicking it opens rofi in drun mode.

## Follow-up

- Update `README.md` to mention the new waybar launcher button, per project convention.
