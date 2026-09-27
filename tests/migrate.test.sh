#!/usr/bin/env bash
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME=$tmp/home PATH=$tmp/mock:$PATH
config=$HOME/.config/omarchy/shell.json
mkdir -p "$HOME/.config/omarchy/plugins/redeye1011.bluetooth-status" "$HOME/.config/omarchy/extensions" "$tmp/mock"
cp "$repo/manifest.json" "$HOME/.config/omarchy/plugins/redeye1011.bluetooth-status/manifest.json"
cat >"$config" <<'JSON'
{"bar":{"layout":{"left":[],"center":[],"right":[
  {"id":"redeye1011.bluetooth-status"},
  {"id":"om.bt-speaker","address":"AA:BB:CC:DD:EE:FF","iconFamily":"b","icon":"󰕾","nameHint":"Desk speaker","showWhenDisconnected":false,"statusStyle":"shape"},
  {"id":"om.bt-earbuds","address":"77:88:99:AA:BB:CC"},
  {"id":"om.bt-mouse","address":"11:22:33:44:55:66","showWhenDisconnected":true},
  {"id":"om.bt-keyboard"}
]}}}
JSON
printf '{}\n' >"$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
for slot in speaker earbuds mouse keyboard settings; do
  mkdir -p "$HOME/.config/omarchy/plugins/om.bt-$slot"
  : >"$HOME/.config/omarchy/plugins/om.bt-$slot/.omarchy-bt-widgets-managed"
done
cat >"$tmp/mock/omarchy-shell" <<'SH'
#!/usr/bin/env bash
[[ $1 == shell && $2 == ping ]]
SH
cat >"$tmp/mock/omarchy" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
config=$HOME/.config/omarchy/shell.json
if [[ $1 == bar && $2 == set ]]; then
  jq --arg id "$3" --arg key "$4" --arg value "$5" --argjson json "$([[ ${6:-} == --json ]] && echo true || echo false)" '
    .bar.layout.right |= map(if .id == $id then .[$key] = (if $json then ($value | fromjson) else $value end) else . end)' "$config" >"$config.tmp"
  mv "$config.tmp" "$config"
elif [[ $1 == plugin && $2 == remove ]]; then
  mv "$HOME/.config/omarchy/plugins/$3" "$HOME/.config/omarchy/plugins/.$3.removed"
  jq --arg id "$3" '.bar.layout.right |= map(select(.id != $id))' "$config" >"$config.tmp"
  mv "$config.tmp" "$config"
else
  exit 1
fi
SH
chmod +x "$tmp/mock/omarchy" "$tmp/mock/omarchy-shell"

# Ownership is checked before any settings are copied or plugins removed.
rm "$HOME/.config/omarchy/plugins/om.bt-mouse/.omarchy-bt-widgets-managed"
if "$repo/bin/migrate-from-bundle" 2>/dev/null; then
  echo 'Migration accepted an unowned plugin' >&2; exit 1
fi
test "$(jq -r '.bar.layout.right[] | select(.id == "redeye1011.bluetooth-status") | .speakerAddress // ""' "$config")" = ''
: >"$HOME/.config/omarchy/plugins/om.bt-mouse/.omarchy-bt-widgets-managed"
"$repo/bin/migrate-from-bundle" >/dev/null
jq -e '[.bar.layout.right[] | select(.id == "redeye1011.bluetooth-status")][0] |
  .speakerAddress == "AA:BB:CC:DD:EE:FF" and .speakerIconFamily == "b" and .speakerIcon == "󰕾" and
  .speakerNameHint == "Desk speaker" and .speakerShowWhenDisconnected == false and
  .earbudsAddress == "77:88:99:AA:BB:CC" and .earbudsShowWhenDisconnected == true and
  .mouseShowWhenDisconnected == true and .statusStyle == "shape"' "$config" >/dev/null
test "$(jq -r '[.bar.layout.right[] | select(.id | startswith("om.bt-"))] | length' "$config")" = 0
test "$(find "$HOME/.config/omarchy" -maxdepth 1 -name 'shell.json.bak.*' | wc -l)" -eq 1
rg -q 'summon redeye1011.bluetooth-status' "$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
"$repo/bin/migrate-from-bundle" | rg -q 'No earlier Bluetooth Status'
printf 'Native migration: OK\n'
