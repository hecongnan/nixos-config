"""Restore selected writable preferences once, without overwriting user changes."""
import argparse
from pathlib import Path
import json
import shutil


def seed(source, destination):
    if not destination.exists() and not destination.is_symlink():
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, destination)
        destination.chmod(0o600)


def seed_json(source, destination, overrides):
    if not destination.exists() and not destination.is_symlink():
        value = json.loads(source.read_text())
        value.update(overrides)
        destination.parent.mkdir(parents=True, exist_ok=True)
        with destination.open('x') as stream:
            json.dump(value, stream, ensure_ascii=False, indent=2)
            stream.write('\n')
        destination.chmod(0o600)


def restore(snapshot, config_home, state_home, wallpaper, mouse_battery=None):
    snapshot, config_home, state_home = map(Path, (snapshot, config_home, state_home))
    dms = config_home / 'DankMaterialShell'
    seed_json(snapshot / 'dms-settings.json', dms / 'settings.json',
              {'lockScreenWallpaperPath': wallpaper})
    for source, name in [('dms-plugin-settings.json', 'plugin_settings.json'),
                         ('dms-plugins.lock.json', 'plugins.lock.json')]:
        seed(snapshot / source, dms / name)
    seed_json(snapshot / 'dms-session.json', state_home / 'DankMaterialShell/session.json',
              {'wallpaperPath': wallpaper})
    plugin = dms / 'plugins/mouseBattery'
    if mouse_battery and not plugin.is_symlink() and (not plugin.exists() or plugin.is_dir()):
        for source in Path(mouse_battery).iterdir():
            seed(source, plugin / source.name)
    for source in (snapshot / 'niri-dms').glob('*.kdl'):
        seed(source, config_home / 'niri/dms' / source.name)
    for name in ('classicui', 'notifications'):
        seed(snapshot / f'fcitx5-{name}.conf', config_home / f'fcitx5/conf/{name}.conf')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--snapshot', required=True)
    parser.add_argument('--config-home', required=True)
    parser.add_argument('--state-home', required=True)
    parser.add_argument('--wallpaper', required=True)
    parser.add_argument('--mouse-battery')
    args = parser.parse_args()
    restore(args.snapshot, args.config_home, args.state_home, args.wallpaper, args.mouse_battery)
