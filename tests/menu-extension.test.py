import runpy
import os
import subprocess
import tempfile
from pathlib import Path

script = Path(__file__).resolve().parents[1] / "bin/menu-extension"
module = runpy.run_path(str(script))
edit, parsed = module["edit"], module["parsed"]

for original in (
    "{}\n",
    '{"setup.other":{"label":"Other"}}\n',
    '{\n  // Keep this comment\n  "setup.other": {"label":"Other"},\n}\n',
    '{"setup.other":{"label":"Other"}}\n// example {id}\n',
):
    installed = edit(original, "add", module["rows"]())
    assert parsed(installed)["setup.bluetooth-widgets"]["label"] == "Bluetooth Status"
    assert "summon redeye1011.bluetooth-status" in parsed(installed)["setup.bluetooth-widgets"]["action"]
    assert installed.count("setup.bluetooth-widgets") == 1
    assert edit(installed, "add", module["rows"]()) == installed
    removed = edit(installed, "remove")
    assert "setup.bluetooth-widgets" not in parsed(removed)
    assert parsed(removed) == parsed(original)

try:
    edit('{"setup.bluetooth-widgets": {"label":"Someone else"}}', "add")
except ValueError:
    pass
else:
    raise AssertionError("unowned menu entry must block install")

with tempfile.TemporaryDirectory() as temp:
    home = Path(temp) / "home"
    menu = home / ".config/omarchy/extensions/omarchy-menu.jsonc"
    menu.parent.mkdir(parents=True)
    target = Path(temp) / "dotfiles-menu.jsonc"
    target.write_text("{}\n")
    menu.symlink_to(target)
    subprocess.run([script, "add"], env={**os.environ, "HOME": str(home)}, check=True)
    assert menu.is_symlink()
    assert "setup.bluetooth-widgets" in target.read_text()
    menu.unlink()
    subprocess.run([script, "add"], env={**os.environ, "HOME": str(home)}, check=True)
    assert menu.stat().st_mode & 0o777 == 0o644

print("Menu extension: OK")
