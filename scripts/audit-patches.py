#!/usr/bin/env python3
"""Read-only checks for deployed Aurora customizations; exit 2 means restart pending."""
import hashlib
import json
import os
from pathlib import Path
import shlex
import subprocess
import sys

results = []


def record(name, status, detail):
    results.append(dict(name=name, status=status, detail=detail))
    print(f"[{status}] {name}: {detail}")


def run(*args):
    return subprocess.check_output(args, text=True, stderr=subprocess.PIPE, timeout=30).strip()


def check(name, callback):
    try:
        detail = callback()
        if detail is not None:
            record(name, 'PASS', detail)
    except Exception as error:
        record(name, 'FAIL', str(error))


def coordinates():
    windows = json.loads(run('niri', 'msg', '-j', 'windows'))
    tiled = [w for w in windows if not w['is_floating']]
    if not tiled:
        record('niri coordinates', 'NOTE', 'No tiled windows available for runtime verification')
        return
    assert all(w['layout']['tile_pos_in_workspace_view'] is not None for w in tiled)
    record('niri coordinates', 'PASS', f'{len(tiled)} tiled windows report positions')


def niri_process():
    pid = run('systemctl', '--user', 'show', 'niri.service', '-p', 'MainPID', '--value')
    actual = Path('/proc', pid, 'exe').resolve(strict=True)
    expected = Path('/run/current-system/sw/bin/niri').resolve(strict=True)
    record('niri process', 'PASS' if actual == expected else 'PENDING',
           str(actual) if actual == expected else f'Re-login required: running {actual}; configured {expected}')


def dms():
    environment = dict(s.split('=', 1) for s in shlex.split(run(
        'systemctl', '--user', 'show', 'dms.service', '-p', 'Environment', '--value')) if '=' in s)
    shell = environment['DMS_SHELL_DIR']
    helper = environment['DMS_TRAY_FOCUS_HELPER']
    assert shell.startswith('/nix/store/') and helper.startswith('/nix/store/'), 'Legacy override still loaded'
    pid = run('systemctl', '--user', 'show', 'dms.service', '-p', 'MainPID', '--value')
    args = Path('/proc', pid, 'cmdline').read_bytes().decode().split('\0')
    configs = [args[i+1] for i, arg in enumerate(args[:-1]) if arg in ('-c', '--config')]
    assert configs and configs[-1] == shell, 'Running CLI config takes precedence over patched UI'
    source = (Path(shell) / 'Modules/DankBar/Widgets/SystemTrayBar.qml').read_text()
    assert source.count('root.activateOrFocusTrayItem(') == 4
    assert os.access(helper, os.X_OK)
    assert run('systemctl', '--user', 'is-active', 'dms.service') == 'active'
    return 'Running CLI selects patched UI; all four tray activation paths and helper present'


def flclash():
    package = Path('/etc/profiles/per-user', os.environ['USER'], 'bin/FlClash').resolve(strict=True).parent.parent
    directory = package / 'opt/FlClash'
    expected = json.loads((directory / 'manifest.json').read_text())['coreSha256']
    actual = hashlib.sha256((directory / 'FlClashCore').read_bytes()).hexdigest()
    assert actual == expected, 'Core differs from helper manifest'
    assert run('systemctl', 'is-active', 'flclash-helper.service') == 'active'
    return 'Core hash matches helper manifest; privileged helper active'


def rime():
    directory = Path.home() / '.local/share/fcitx5/rime'
    assert 'schema: rime_ice' in (directory / 'default.custom.yaml').read_text()
    assert 'schema: rime_ice' in (directory / 'build/default.yaml').read_text()
    assert 'schema_id: rime_ice' in (directory / 'build/rime_ice.schema.yaml').read_text()
    assert run('systemctl', '--user', 'is-active', 'fcitx5-daemon.service') == 'active'
    return 'Rime Ice configuration deployed and input method active'


def computer_use():
    executable = Path('/run/current-system/sw/bin/codex-computer-use')
    doctor = json.loads(run(str(executable), 'doctor'))
    readiness = doctor['readiness']
    assert not readiness['blockers'], readiness['blockers']
    for key in ['can_build_accessibility_tree', 'can_query_windows', 'can_send_development_input']:
        assert readiness[key], key
    return 'Doctor reports window targeting, accessibility and input ready; no blockers'


def panel():
    expected = (Path(__file__).resolve().parents[1] / 'hosts/aurora/edid/panel-60hz.bin').read_bytes()
    paths = list(Path('/sys/class/drm').glob('*-eDP-1/edid'))
    assert paths and any(p.read_bytes() == expected for p in paths), 'EDID differs or panel unavailable'
    return 'Panel EDID matches configured 60 Hz override'


def config():
    run('/run/current-system/sw/bin/niri', 'validate')
    directory = Path.home() / '.config/niri'
    text = (directory / 'config.kdl').read_text()
    for name in ['scratchpad.kdl', 'computer-use.kdl']:
        assert f'"{name}"' in text and (directory / name).exists()
    return 'Configuration validates; scratchpad and agent window rules included'


check('niri runtime coordinates', coordinates)
check('niri running version', niri_process)
check('niri configuration', config)
check('DMS tray focus', dms)
check('Codex computer-use', computer_use)
check('FlClash helper integrity', flclash)
check('Rime Ice', rime)
check('Panel EDID', panel)
booted = Path('/run/booted-system').resolve()
current = Path('/run/current-system').resolve()
if booted == current:
    record('Boot generation', 'PASS', 'Booted generation matches current')
elif all((booted / name).resolve(strict=True) == (current / name).resolve(strict=True)
         for name in ('kernel', 'initrd')):
    record('Boot generation', 'NOTE', 'Generation differs; kernel and initrd match current')
else:
    record('Boot generation', 'PENDING', 'Reboot required to load the current kernel/initrd')
summary = {status: sum(r['status'] == status for r in results) for status in ['PASS', 'FAIL', 'PENDING', 'NOTE']}
print(json.dumps(summary, ensure_ascii=False))
sys.exit(1 if summary['FAIL'] else 2 if summary['PENDING'] else 0)
