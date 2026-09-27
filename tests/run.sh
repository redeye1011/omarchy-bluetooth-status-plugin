#!/usr/bin/env bash
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

omarchy plugin validate "$repo" >/dev/null
python3 - "$repo" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1]) / "icons"
for slot, device in (("speaker", "Speaker"), ("earbuds", "Headphones"),
                     ("mouse", "Mouse"), ("keyboard", "Keyboard")):
    for family in "ABC":
        for variant in ("", "Filled", "Outline"):
            asset = root / f"Menu{family}{device}{variant}.png"
            assert asset.read_bytes().startswith(b"\x89PNG\r\n\x1a\n"), asset
PY
node "$repo/tests/model.test.js"
python3 "$repo/tests/menu-extension.test.py"
bash "$repo/tests/native.test.sh"
bash "$repo/tests/migrate.test.sh"
"$repo/bin/omarchy-bt-widgets" selfcheck >/dev/null
printf 'All checks passed.\n'
