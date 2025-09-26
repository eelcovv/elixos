# Waybar Configuration Guide

This document explains the layout of the Waybar configuration in this repo, how the **switching mechanism** works 
(for themes/variants), and how to run/debug it. 
Examples use Linux paths and a Home‑Manager/NixOS style setup, but the structure also works standalone.

---

## TL;DR

- **`~/.config/waybar/config.jsonc`** → main configuration (includes modules file; JSON with comments).
- **`~/.config/waybar/style.css`** → active stylesheet for the current theme.
- **`~/.config/waybar/modules.jsonc`** → module definitions and order (shared across themes).
- **`~/.config/waybar/themes/<family>/<variant>/`** → theme families and variants.
- **Switching** = update a couple of **symlinks**:
  - `~/.config/waybar/config.jsonc` → points to a family’s `config.jsonc` (or a shared one).
  - `~/.config/waybar/style.css` → points to the selected variant’s `style.css`.
  - optional: `~/.config/waybar/current` → symlink to the **selected variant** directory.

---

## Directory Layout

```shell
~/.config/waybar/
├── config                # symlink to config.jsonc (Waybar resolves both)
├── config.jsonc          # symlink → themes/<family>/config.jsonc (or a shared file)
├── style.css             # symlink → themes/<family>/<variant>/style.css
├── modules.jsonc         # shared modules (order, tooltip, format, etc.)
├── colors.css            # optional palette shared by themes
├── current/              # optional: symlink pointing at the *active variant*
└── themes/
    ├── default/
    │   ├── config.jsonc  # family-level config (includes modules.jsonc)
    │   └── style.css     # minimal baseline theme
    └── ml4w-blur/
        ├── config.jsonc  # family-level config (can be shared across variants)
        ├── style.css     # family-level style.css 
        ├── light/style.css # variant style file
        └── dark/style.css 
```

### Notes

- Each **theme family** owns a `config.jsonc` and a base `style.css`. Variants under the family (e.g. `light/`, `dark/`) only provide `style.css`.
- The `style.css` of the variant imports the `style.css` of the family, such
  that small alterations of colors can be down per variation.
- `modules.jsonc` is shared so you don’t have to duplicate module configuration per theme.
- If your family design diverges a lot, you can still place a separate `modules.jsonc` under that family and include
  that instead.

---

## Switching Mechanism (Symlink-based)

Switching themes/variants is done by moving symlinks. Example: switch to family `ml4w-blur` and variant `light`.

```bash
# 1) Point the global Waybar config to the family config (one per family)
ln -sfn "$HOME/.config/waybar/themes/ml4w-blur/config.jsonc"        "$HOME/.config/waybar/config.jsonc"

# 2) Point the stylesheet to the chosen *variant*
ln -sfn "$HOME/.config/waybar/themes/ml4w-blur/light/style.css"        "$HOME/.config/waybar/style.css"

# 3) (Optional) Maintain a 'current' marker
ln -sfn "$HOME/.config/waybar/themes/ml4w-blur/light"        "$HOME/.config/waybar/current"

# 4) Restart Waybar
pkill -x waybar || true
waybar -l info -c "$HOME/.config/waybar/config.jsonc" -s "$HOME/.config/waybar/style.css"
```

**Why two symlinks?**

- A **family** config (`config.jsonc`) can be reused across its variants.
- The **variant** is purely a CSS choice (`style.css`).

---

## Config Includes

The family `config.jsonc` usually includes `modules.jsonc` and optional extras. Example skeleton:

```jsonc
{
  // Family-level config; keep this minimal and stable per theme family
  "layer": "top",
  "position": "top",
  "include": [
    "~/.config/waybar/modules.jsonc"
  ],
  "modules-left": ["custom/menu", "hyprland/workspaces"],
  "modules-center": ["clock"],
  "modules-right": ["network", "pulseaudio", "battery"]
}
```

Shared `modules.jsonc` holds deeper module configuration and ordering:

```jsonc
{
  "custom/menu": {
    "format": "",
    "tooltip": false
  },
  "clock": {
    "format": "{:%a %d %b %H:%M}",
    "tooltip": true
  },
  "network": {
    "format-wifi": "󰤨  {essid} ({signalStrength}%)",
    "format-ethernet": "󰈀  {ifname}",
    "tooltip": true
  }
}
```

---

## Theming (CSS)

Each variant ships its own `style.css`. Keep variables/palette in `colors.css` (optional) and import it:

```css
/* themes/ml4w-blur/light/style.css */
@import url("~/.config/waybar/colors.css");

window {
  font-family: Roboto, sans-serif;
  background: rgba(20, 22, 30, 0.6);
  backdrop-filter: blur(10px);
}

#clock {
  padding: 0 10px;
}
```

---

## Variant Stylesheets and Inheritance

Theme **variants** (e.g. `light/`, `dark/`) usually contain their own `style.css`.  
Each of these starts with an `@import` pointing back to the **parent family’s** base `style.css`:

```css
/* themes/ml4w-blur/light/style.css */
@import url("../style.css");

/* Add only overrides below */
#clock {
  color: black;
}
```

Because of this `../style.css` import:

- The **family root** must also provide a `style.css` (the baseline).
- Each **variant directory** must live **one level deeper** (e.g. `themes/ml4w-blur/light/style.css`).
- This way, common styles are centralized in the family’s `style.css`, and each variant only defines overrides.

---

## Managed Startup (systemd --user)

If you start Waybar automatically under Hyprland (or another session), use a user service. Example template:

```ini
# ~/.config/systemd/user/waybar-managed.service
[Unit]
Description=Waybar (managed)
PartOf=hyprland-session.target
After=hyprland-session.target

[Service]
Type=simple
ExecStart=/usr/bin/waybar -l info -c %h/.config/waybar/config.jsonc -s %h/.config/waybar/style.css
Restart=on-failure

[Install]
# Typically hooked in via hyprland-session.target
```

Reload & (re)start:

```bash
systemctl --user daemon-reload
systemctl --user restart waybar-managed
```

---

## NixOS / Home‑Manager Notes

- Prefer writing the *source of truth* in your repo under `home/modules/` or similar.
- Use Home‑Manager to place files and create the **symlinks** shown above.
- Keep the **switching logic** in a small script (e.g., `~/bin/waybar-switch`) that simply updates the symlinks and restarts Waybar.

Example switch script:

```bash
#!/usr/bin/env bash
set -euo pipefail

family="${1:-ml4w-blur}"
variant="${2:-light}"
base="$HOME/.config/waybar"

ln -sfn "$base/themes/$family/config.jsonc" "$base/config.jsonc"
ln -sfn "$base/themes/$family/$variant/style.css" "$base/style.css"
ln -sfn "$base/themes/$family/$variant" "$base/current"

pkill -x waybar || true
waybar -l info -c "$base/config.jsonc" -s "$base/style.css" &
```

---

## Debugging & Tips

- Run Waybar in a terminal with **trace logs**:

```bash
pkill -x waybar || true
waybar -l trace -c ~/.config/waybar/config.jsonc -s ~/.config/waybar/style.css
```

- If an `include` path fails, Waybar will log the unresolved path. Expand `~` manually if needed.
- If CSS doesn’t seem to apply, confirm `style.css` points to the **intended variant** and reload.
- Keep **module logic** and **theme CSS** separate—switching variants then becomes instant and safe.

---

## FAQ

**Q: Why keep `modules.jsonc` separate from themes?**  
A: Most users change **appearance** more often than **module composition**. Sharing `modules.jsonc` avoids duplication and keeps switching atomic.

**Q: Can a family have its *own* modules file?**  
A: Yes. Point the family `config.jsonc` to a different include if the family diverges.

**Q: Do I need both `config` and `config.jsonc`?**  
A: Waybar accepts either. Keeping `config.jsonc` as the canonical symlink is tidy; `config` can be a convenience symlink.

---

## License

If you publish this theme/config, add your preferred license here (e.g., MIT).
