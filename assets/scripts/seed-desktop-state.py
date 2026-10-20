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


def restore(snapshot, config_home, state_home, wallpaper):
    snapshot, config_home, state_home = map(Path, (snapshot, config_home, state_home))
    dms = config_home / 'DankMaterialShell'
    for source, name in [('dms-settings.json', 'settings.json'),
                         ('dms-plugin-settings.json', 'plugin_settings.json'),
                         ('dms-plugins.lock.json', 'plugins.lock.json')]:
        seed(snapshot / source, dms / name)
    session = state_home / 'DankMaterialShell/session.json'
    if not session.exists() and not session.is_symlink():
        value = json.loads((snapshot / 'dms-session.json').read_text())
        value['wallpaperPath'] = wallpaper
        session.parent.mkdir(parents=True, exist_ok=True)
        with session.open('x') as stream:
            json.dump(value, stream, ensure_ascii=False, indent=2)
            stream.write('\n')
        session.chmod(0o600)
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
    args = parser.parse_args()
    restore(args.snapshot, args.config_home, args.state_home, args.wallpaper)
