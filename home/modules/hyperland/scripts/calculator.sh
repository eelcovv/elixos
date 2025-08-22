#!/usr/bin/env bash
set -euo pipefail

notify() { command -v notify-send >/dev/null 2>&1 && notify-send "Calculator" "$*"; }
copy()    { command -v wl-copy >/dev/null 2>&1 && printf "%s" "$1" | wl-copy; }

# 1) Prefer a real GUI calculator if present
for gui in gnome-calculator qalculate-gtk kcalc mate-calc; do
  if command -v "$gui" >/dev/null 2>&1; then exec "$gui"; fi
done

# 2) Fallback: prompt → evaluate → notify + copy
if ! command -v wofi >/dev/null 2>&1; then
  echo "No GUI calculator; install gnome-calculator or qalculate-gtk." >&2
  exit 1
fi

expr="$(wofi --dmenu -p 'calc:' || true)"
[ -z "${expr}" ] && exit 0

result=""
if command -v bc >/dev/null 2>&1; then
  # bc -l: floating point, mathlib
  result="$(printf '%s\n' "$expr" | bc -l 2>/dev/null || true)"
fi

# If bc failed/absent, try a minimal Python eval with math only
if [ -z "${result}" ] && command -v python3 >/dev/null 2>&1; then
  result="$(python3 - <<'PY' 2>/dev/null || true
import math, sys
expr = sys.stdin.read().strip()
# Extremely minimal sandbox: no builtins, expose math only
safe_globals = {"__builtins__": None, "math": math}
try:
    val = eval(expr, safe_globals, {})
    # Pretty print floats without trailing .0 noise
    if isinstance(val, float):
        print(f"{val:.12g}")
    else:
        print(val)
except Exception:
    pass
PY
  <<<"$expr")"
fi

[ -z "${result}" ] && { notify "Invalid expression"; exit 1; }

copy "${result}"
notify "${expr} = ${result}"
printf '%s\n' "${result}"
