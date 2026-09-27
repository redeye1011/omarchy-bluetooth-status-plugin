#!/usr/bin/env bash
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

test "$(find "$repo" -path "$repo/.git" -prune -o -name manifest.json -print | wc -l)" -eq 1
jq -e '.id == "redeye1011.bluetooth-status" and
  (.kinds | index("bar-widget") != null and index("panel") != null) and
  .entryPoints.barWidget == "BarWidget.qml" and .entryPoints.panel == "Panel.qml"' \
  "$repo/manifest.json" >/dev/null
test -x "$repo/bin/omarchy-bt-widgets"
test -x "$repo/bin/menu-extension"
test -x "$repo/bin/migrate-from-bundle"
lint=$(command -v qmllint || true)
[[ -n $lint ]] || lint=/usr/lib/qt6/bin/qmllint
if [[ -x $lint ]]; then
  "$lint" "$repo/BarWidget.qml" "$repo/SlotIcon.qml" "$repo/Panel.qml" >/dev/null 2>&1
fi
if command -v tesseract >/dev/null; then
  for preview in "$repo/preview.png" "$repo/preview-device.png"; do
    if tesseract "$preview" stdout 2>/dev/null | rg -qi '([0-9a-f]{2}:){5}[0-9a-f]{2}'; then
      echo "Bluetooth address visible in $preview" >&2
      exit 1
    fi
  done
fi
printf 'Native plugin structure: OK\n'
