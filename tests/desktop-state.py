"""Check restore-once semantics without touching the real home directory."""
import importlib.util
import json
from pathlib import Path
import sys
import tempfile

spec = importlib.util.spec_from_file_location('seed', sys.argv[1])
seed = importlib.util.module_from_spec(spec)
spec.loader.exec_module(seed)
snapshot = Path(sys.argv[2])
with tempfile.TemporaryDirectory() as temp:
    root = Path(temp)
    config, state = root / 'config', root / 'state'
    package = root / 'package'
    package.mkdir()
    (package / 'plugin.json').write_text('{"id": "mouseBattery"}')
    seed.restore(snapshot, config, state, '/test/wallpaper.svg', package)
    settings = config / 'DankMaterialShell/settings.json'
    plugin = config / 'DankMaterialShell/plugins/mouseBattery/plugin.json'
    assert json.loads(settings.read_text())['blurWallpaperOnOverview'] is True
    assert json.loads(settings.read_text())['lockScreenWallpaperPath'] == '/test/wallpaper.svg'
    assert json.loads((config / 'DankMaterialShell/plugin_settings.json').read_text())['quickCapture']['enabled']
    assert json.loads((config / 'DankMaterialShell/plugin_settings.json').read_text())['mouseBattery']['enabled']
    assert json.loads(plugin.read_text())['id'] == 'mouseBattery'
    assert json.loads((state / 'DankMaterialShell/session.json').read_text())['wallpaperPath'] == '/test/wallpaper.svg'
    assert 'gaps 4' in (config / 'niri/dms/layout.kdl').read_text()
    assert 'output "eDP-1"' not in (config / 'niri/dms/outputs.kdl').read_text()
    assert 'spawn "dux-random-wallpaper"' in (config / 'niri/dms/binds.kdl').read_text()
    assert (config / 'fcitx5/conf/classicui.conf').exists()
    settings.write_text('{"userEdited": true}')
    plugin.write_text('{"userEdited": true}')
    seed.restore(snapshot, config, state, '/different/wallpaper.svg', package)
    assert settings.read_text() == '{"userEdited": true}'
    assert plugin.read_text() == '{"userEdited": true}'
    assert json.loads((state / 'DankMaterialShell/session.json').read_text())['wallpaperPath'] == '/test/wallpaper.svg'
    assert settings.stat().st_mode & 0o777 == 0o600
print('Desktop seed restore and user-edit preservation passed')
