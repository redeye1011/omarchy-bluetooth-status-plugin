#!/usr/bin/env bash
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

omarchy plugin validate "$repo" >/dev/null
python3 "$repo/tests/icons.test.py"
qmlformat_bin=$(command -v qmlformat || true)
[[ -n $qmlformat_bin ]] || qmlformat_bin=/usr/lib/qt6/bin/qmlformat
"$qmlformat_bin" "$repo/Panel.qml" >/dev/null
"$qmlformat_bin" "$repo/SlotIcon.qml" >/dev/null
node "$repo/tests/model.test.js"
python3 "$repo/tests/menu-extension.test.py"
bash "$repo/tests/native.test.sh"
bash "$repo/tests/migrate.test.sh"
"$repo/bin/omarchy-bt-widgets" selfcheck >/dev/null
printf 'All checks passed.\n'
